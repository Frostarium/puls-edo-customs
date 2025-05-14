--Nex Ultima
local s,id=GetID()
function s.initial_effect(c)
    --Track Level 12 Fusion summons
    aux.GlobalCheck(s,function()
        local ge1=Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
        ge1:SetOperation(s.checkop)
        Duel.RegisterEffect(ge1,0)
    end)
    	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
    --Add banished cards
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    --Negate and banish
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.negcon)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
    --Set from banished
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_REMOVED)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.setcon)
    e3:SetTarget(s.settg)
    e3:SetOperation(s.setop)
    c:RegisterEffect(e3)
end

function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    local tc=eg:GetFirst()
    while tc do
        if tc:IsType(TYPE_FUSION) and tc:IsLevel(12) then
            Duel.RegisterFlagEffect(tc:GetSummonPlayer(),id,RESET_PHASE+PHASE_END,0,1)
        end
        tc=eg:GetNext()
    end
end

function s.cfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x456) and c:IsLevelAbove(8)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase() and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,LOCATION_REMOVED,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_REMOVED)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,LOCATION_REMOVED,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

function s.fusfilter(c,tp)
    return c:IsFaceup() and c:IsType(TYPE_FUSION) and c:IsLevel(12) and c:IsSummonPlayer(tp)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.fusfilter,1,nil,tp)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsNegatable,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    local g=Duel.SelectMatchingCard(tp,Card.IsNegatable,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        Duel.NegateRelatedChain(tc,RESET_TURN_SET)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        tc:RegisterEffect(e2)
        Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
    end
end

function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFlagEffect(tp,id)>0
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsSSetable() end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsSSetable() then
        Duel.SSet(tp,c)
    end
end
