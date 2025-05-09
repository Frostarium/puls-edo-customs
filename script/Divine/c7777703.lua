--The Realm of the Divine
local s,id=GetID()
function s.initial_effect(c)
    --Activation
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    --Search
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_FZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    --Protection
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetRange(LOCATION_FZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(s.indtg)
    e3:SetValue(aux.indoval)
    c:RegisterEffect(e3)
    --Annihilation
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_FZONE)
    e4:SetCondition(s.anhcon)
    e4:SetOperation(s.anhop)
    c:RegisterEffect(e4)
    --Remove from GY
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_PHASE+PHASE_END)
    e5:SetRange(LOCATION_FZONE)
    e5:SetCountLimit(1,{id,1})
    e5:SetCondition(s.rmcon)
    e5:SetOperation(s.rmop)
    c:RegisterEffect(e5)
end
function s.thfilter(c)
    return c:IsAttribute(ATTRIBUTE_DIVINE) and c:IsAbleToHand() or (c:IsSpell() or c:IsTrap()) and c:IsSetCard(0x777)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
function s.indtg(e,c)
    return c:IsAttribute(ATTRIBUTE_DIVINE)
end
function s.anhfilter(c)
    return c:IsAttribute(ATTRIBUTE_DIVINE) and c:IsLevelAbove(11)
end
function s.anhcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.anhfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,2,nil)
        and eg:IsExists(Card.IsControler,1,nil,1-tp)
end
function s.anhop(e,tp,eg,ep,ev,re,r,rp)
    if ep==tp or not re:GetActivateLocation()==LOCATION_GRAVE then return end
    Duel.NegateEffect(ev)
    local g=Group.FromCards(re:GetHandler())
    if #g>0 then
        Duel.RemoveCards(g)
    end
end
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.anhfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,2,nil)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
    if #g>0 then
        Duel.RemoveCards(g)
    end
end