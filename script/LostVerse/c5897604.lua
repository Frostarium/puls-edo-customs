--The Lost Universes
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    --ATK/DEF boost for Lost Universe normal monsters
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(s.stattg)
    e2:SetValue(1000)
    e2:SetRange(LOCATION_FZONE)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e3)
    --Cannot be targeted by opponent's effects
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e4:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
    e4:SetTargetRange(LOCATION_MZONE,0)
    e4:SetTarget(s.stattg)
    e4:SetValue(aux.tgoval)
    e4:SetRange(LOCATION_FZONE)
    c:RegisterEffect(e4)
    --Cannot be destroyed by opponent's effects
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e5:SetTargetRange(LOCATION_MZONE,0)
    e5:SetTarget(s.stattg)
    e5:SetValue(aux.indoval)
    e5:SetRange(LOCATION_FZONE)
    c:RegisterEffect(e5)
    --Search
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,1))
    e6:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_FZONE)
    e6:SetCountLimit(1)
    e6:SetCondition(s.srchcon)
    e6:SetTarget(s.srchtg)
    e6:SetOperation(s.srchop)
    c:RegisterEffect(e6)
end

function s.stattg(e,c)
    return c:IsSetCard(0x5bc) and c:IsType(TYPE_NORMAL)
end

function s.srchcon(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
    return #g==0 or g:IsExists(Card.IsType,1,nil,TYPE_NORMAL)
end

function s.srchfilter(c)
    return c:IsSetCard(0x5bc) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.srchtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.srchfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.srchop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.srchfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
