--The Lost Universes
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    --Cannot be targeted/destroyed
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
    e2:SetRange(LOCATION_FZONE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(s.immtg)
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetValue(1)
    c:RegisterEffect(e3)
    --ATK/DEF boost
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetTargetRange(LOCATION_MZONE,0)
    e4:SetTarget(s.immtg)
    e4:SetValue(1000)
    e4:SetRange(LOCATION_FZONE)
    c:RegisterEffect(e4)
    local e5=e4:Clone()
    e5:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e5)
    --Grant effect to Lost Universe normal monsters
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_ADJUST)
    e6:SetRange(LOCATION_FZONE)
    e6:SetOperation(s.grantop)
    c:RegisterEffect(e6)
end

local affected_cards={}

function s.immtg(e,c)
    return c:IsSetCard(0x5bc) and c:IsType(TYPE_NORMAL)
end

function s.grantop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,0x5bc),tp,LOCATION_MZONE,0,nil)
    for tc in aux.Next(g) do
        if tc:IsType(TYPE_NORMAL) and not affected_cards[tc] then
            --Negate activation
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetDescription(aux.Stringid(id,0))
            e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
            e1:SetType(EFFECT_TYPE_QUICK_O)
            e1:SetCode(EVENT_CHAINING)
            e1:SetRange(LOCATION_MZONE)
            e1:SetCountLimit(1)
            e1:SetCondition(s.negcon)
            e1:SetTarget(s.negtg)
            e1:SetOperation(s.negop)
            tc:RegisterEffect(e1)
            affected_cards[tc]=true
            tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,0)
        end
    end
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
        and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    local rc=re:GetHandler()
    if rc:IsAbleToRemove() and rc:IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
    end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local rc=re:GetHandler()
    if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
        Duel.Remove(rc,POS_FACEDOWN,REASON_EFFECT)
    end
end
