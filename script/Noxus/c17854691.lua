--Sahn Uzal
local s,id=GetID()
function s.initial_effect(c)
    --Hand effect: reveal to search
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,{id,0})  
    e1:SetCost(s.thcost)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    
    --Special summon from deck when Nox monster destroyed
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_DECK)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    
    --Double battle phase if special summoned from deck
    local e2b=Effect.CreateEffect(c)
    e2b:SetDescription(aux.Stringid(id,3))
    e2b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2b:SetCountLimit(1,{id,2})
    e2b:SetCondition(s.bpcon)
    e2b:SetOperation(s.bpop)
    c:RegisterEffect(e2b)
    
    --Gain ATK/DEF and banish when destroying by battle
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_REMOVE+CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e3:SetCode(EVENT_BATTLE_DESTROYING)
    e3:SetCondition(aux.bdcon)
    e3:SetOperation(s.atkop)
    c:RegisterEffect(e3)
end

--Hand effect functions
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.ConfirmCards(1-tp,e:GetHandler())
end

function s.thfilter(c)
    return c:IsSetCard(0x1735) and c:IsLevelBelow(4) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
        local c=e:GetHandler()
        if c:IsRelateToEffect(e) then
            Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
        Duel.ShuffleDeck(tp)
    end
end

--Special summon functions
function s.spfilter(c,tp)
    return c:IsSetCard(0x1735) and c:IsLevelAbove(7) and c:IsPreviousControler(tp) and c:IsReason(REASON_DESTROY)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.spfilter,1,nil,tp)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

--Double battle phase functions
function s.bpcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_DECK)
end

function s.bpop(e,tp,eg,ep,ev,re,r,rp)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_BP_TWICE)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetTargetRange(1,0)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

--Battle destruction functions
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    if bc and c:IsRelateToEffect(e) and c:IsFaceup() and bc:IsLocation(LOCATION_GRAVE) then
        local atk=bc:GetBaseAttack()
        local def=bc:GetBaseDefense()
        if atk>=0 then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(atk)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
            c:RegisterEffect(e1)
        end
        if def>=0 then
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_UPDATE_DEFENSE)
            e2:SetValue(def)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
            c:RegisterEffect(e2)
        end
        Duel.Remove(bc,POS_FACEUP,REASON_EFFECT)
    end
end
