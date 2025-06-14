--Reckoning Fields
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)
    --Give 0x1735 monsters 500 ATK
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_FZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.atktg)
    e1:SetValue(500)
    c:RegisterEffect(e1)
    --Negate and destroy lower ATK summoned monsters
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_FZONE)
    e2:SetCountLimit(2)
    e2:SetCondition(s.negcon)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
    --Search when monster is destroyed
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_DESTROYED)
    e4:SetRange(LOCATION_FZONE)
    e4:SetCountLimit(1,{id,1})
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCondition(s.thcon2)
    e4:SetTarget(s.thtg2)
    e4:SetOperation(s.thop2)
    c:RegisterEffect(e4)
end

function s.atktg(e,c)
    return c:IsSetCard(0x1735)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    local tc=eg:GetFirst()
    if tc:IsControler(tp) or not tc:IsFaceup() then return false end
    return Duel.IsExistingMatchingCard(s.atkfilter,tp,LOCATION_MZONE,0,1,nil,tc:GetAttack())
end

function s.atkfilter(c,atk)
    return c:IsFaceup() and c:GetAttack()>atk
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local tc=eg:GetFirst()
    if chk==0 then return tc:IsCanBeDisabledByEffect(e) end
    Duel.SetTargetCard(tc)
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,tc,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,tc,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        Duel.NegateRelatedChain(tc,RESET_TURN_SET)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetValue(RESET_TURN_SET)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
        Duel.Destroy(tc,REASON_EFFECT)
    end
end

function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(Card.IsMonster,1,nil)
end

function s.thfilter(c)
    return c:IsSetCard(0x1735) and c:IsAbleToHand()
end

function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop2(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
