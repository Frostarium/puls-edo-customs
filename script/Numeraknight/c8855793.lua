--Numeraknight Differential
local s,id=GetID()
function s.initial_effect(c)
    --Destroy cards
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)
    --Special Summon from GY
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DISABLE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() end
    local ct=Duel.GetMatchingGroup(Card.HasLevel,tp,LOCATION_MZONE,0,nil):GetClassCount(Card.GetLevel)
    if chk==0 then return ct>0 and Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,ct,e:GetHandler())
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end

function s.spfilter1(c,e,tp)
    return c:IsSetCard(0x657) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spfilter2(c,lv,tp)
    return c:IsFaceup() and c:IsControler(1-tp) and (not c:HasLevel() or c:GetLevel()==lv)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    local g=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_GRAVE,0,nil,e,tp)
    if chk==0 then 
        if #g==0 then return false end
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and g:IsExists(function(c)
                return Duel.IsExistingTarget(s.spfilter2,tp,0,LOCATION_MZONE,1,nil,c:GetLevel(),tp)
            end,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sc=g:FilterSelect(tp,function(c)
        return Duel.IsExistingTarget(s.spfilter2,tp,0,LOCATION_MZONE,1,nil,c:GetLevel(),tp)
    end,1,1,nil):GetFirst()
    Duel.SelectTarget(tp,s.spfilter1,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    Duel.SelectTarget(tp,s.spfilter2,tp,0,LOCATION_MZONE,1,1,nil,sc:GetLevel(),tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g1,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g2,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g~=2 then return end
    local tc1,tc2=g:GetFirst(),g:GetNext()
    if tc1:IsControler(1-tp) then tc1,tc2=tc2,tc1 end
    if tc1:IsRelateToEffect(e) and Duel.SpecialSummon(tc1,0,tp,tp,false,false,POS_FACEUP)>0
        and tc2:IsRelateToEffect(e) and tc2:IsFaceup() then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc2:RegisterEffect(e1)
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc2:RegisterEffect(e2)
    end
end
