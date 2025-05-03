--Twin-Headed Red-Eyes Dragon
local s,id=GetID()
function s.initial_effect(c)
    --Fusion material
    c:EnableReviveLimit()
    Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0x3b),aux.FilterBoolFunctionEx(Card.IsSetCard,0x3b))
    --Fusion summon as a Quick Effect (Main Phase only)
    local e0=Fusion.CreateSummonEff(c,nil,nil,s.fextra,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,s.extratg)
    e0:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e0:SetType(EFFECT_TYPE_QUICK_O)
    e0:SetCode(EVENT_FREE_CHAIN)
    e0:SetHintTiming(0,TIMING_MAIN_END)
    e0:SetCondition(function(e,tp) return Duel.IsMainPhase() and Duel.IsTurnPlayer(tp) end)
    c:RegisterEffect(e0)
    --Destroy 2 cards on field when Special Summoned
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)
    --Banish until End Phase when opponent activates effect (Once per Duel)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_DUEL)
    e2:SetCondition(s.bancon)
    e2:SetTarget(s.bantg)
    e2:SetOperation(s.banop)
    c:RegisterEffect(e2)
end
s.material_setcode=SET_RED_EYES
--Destroy 2 cards
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() end
    if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,2,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,2,2,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,2,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end

--Banish self condition
function s.bancon(e,tp,eg,ep,ev,re,r,rp)
    return ep==1-tp
end

--Banish self target
function s.redeyesfilter(c)
    return c:IsSetCard(0x3b) and c:IsMonster()
end

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemove() 
        and Duel.IsExistingMatchingCard(s.redeyesfilter,tp,LOCATION_GRAVE,0,2,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.redeyesfilter,tp,LOCATION_GRAVE,0,2,2,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g:GetFirst(),1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g:GetNext(),1,0,0)
end

--Banish self operation
function s.banop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tg=Duel.GetTargetCards(e)
    if not c:IsRelateToEffect(e) or #tg<2 then return end
    
    if Duel.Remove(c,POS_FACEUP,REASON_EFFECT+REASON_TEMPORARY)~=0 then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_PHASE+PHASE_END)
        e1:SetReset(RESET_PHASE+PHASE_END)
        e1:SetLabelObject(c)
        e1:SetCountLimit(1)
        e1:SetOperation(s.retop)
        Duel.RegisterEffect(e1,tp)
        
        local tc1=tg:GetFirst()
        local tc2=tg:GetNext()
        if tc1 and tc2 then
            Duel.SendtoHand(tc1,nil,REASON_EFFECT)
            Duel.SpecialSummon(tc2,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end

--Return from banish at End Phase
function s.retop(e,tp,eg,ep,ev,re,r,rp)
    Duel.ReturnToField(e:GetLabelObject())
end

--Quick Fusion effect helper functions
function s.fextra(e,tp,mg)
    if not Duel.IsMainPhase() or not Duel.IsTurnPlayer(tp) then return nil end
    return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsAbleToGrave),tp,LOCATION_DECK,0,nil)
end

function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,0,tp,LOCATION_DECK)
end
