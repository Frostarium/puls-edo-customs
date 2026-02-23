--CPU Reflect Barrier
local s, id = GetID()
function s.initial_effect(c)
	local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)	
    c:RegisterEffect(e1)
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1)
	e2:SetCondition(s.cpcon)
	e2:SetTarget(s.cptarget)
	e2:SetOperation(s.cpop)
	c:RegisterEffect(e2)
end
function s.cpcon (e,tp,eg,ep,ev,re,r,rp)
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	return tg and tg:IsExists(Card.IsOnField,1,nil) and Duel.IsChainNegatable(ev)
end
function s.cptarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.cpop(e,tp,eg,ep,ev,re,r,rp)
    --negate the effect
    if not Duel.NegateEffect(ev) then return end

    --retrieve the effect
    local te=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_EFFECT)
    if not te then return end

    local tg=te:GetTarget()
    if tg then
        --check activation legality
        if not tg(te,tp,Group.CreateGroup(),PLAYER_NONE,0,e,REASON_EFFECT,PLAYER_NONE,0) then return end
        --perform activation procedure
        tg(te,tp,Group.CreateGroup(),PLAYER_NONE,0,e,REASON_EFFECT,PLAYER_NONE,1)
    end
    local tc=te:GetHandler()
    Duel.BreakEffect()
    tc:CreateEffectRelation(te)
    Duel.BreakEffect()
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    for etc in aux.Next(g) do
        etc:CreateEffectRelation(te)
    end

    --perform the effect
    local op=te:GetOperation()
    if op then op(te,tp,Group.CreateGroup(),PLAYER_NONE,0,e,REASON_EFFECT,PLAYER_NONE,1) end

    tc:ReleaseEffectRelation(te)
    for etc in aux.Next(g) do
        etc:ReleaseEffectRelation(te)
    end
end