--The Lost Universes
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    --ATK/DEF boost
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
    --Grant protection to Lost Universe normal monsters
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_ADJUST)
    e4:SetRange(LOCATION_FZONE)
    e4:SetOperation(s.grantop)
    c:RegisterEffect(e4)
    --Search
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_FZONE)
    e5:SetCountLimit(1)
    e5:SetCondition(s.srchcon)
    e5:SetTarget(s.srchtg)
    e5:SetOperation(s.srchop)
    c:RegisterEffect(e5)
end

local affected_cards={}

function s.stattg(e,c)
    return c:IsType(TYPE_NORMAL)
end

function s.grantop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,0x5bc),tp,LOCATION_MZONE,0,nil)
    for tc in aux.Next(g) do
        if tc:IsType(TYPE_NORMAL) and not affected_cards[tc] then
            --Grant targeting protection
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
            e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
            e1:SetValue(aux.tgoval)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1)
            --Grant destruction protection
            local e2=Effect.CreateEffect(e:GetHandler())
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
            e2:SetValue(1)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e2)
            affected_cards[tc]=true
            tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,0)
        end
    end
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
