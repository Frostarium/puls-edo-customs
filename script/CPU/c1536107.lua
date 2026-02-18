--CPU Reflect Barrier
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	-- Effect 1: Redirect target
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,{id,0})
	e2:SetCondition(s.redircon)
	e2:SetOperation(s.redirop)
	c:RegisterEffect(e2)

	-- Effect 2: Discard 1 to draw 2 (once per turn)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DRAW+CATEGORY_HANDES)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.drcost)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

-- Effect 1: Redirect
function s.redircon(e,tp,eg,ep,ev,re,r,rp)
	if rp~=1-tp or not re or not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	if not tg or #tg~=1 then return false end
	local tc=tg:GetFirst()
	return tc:IsControler(tp) and tc:IsOnField() and Duel.IsExistingMatchingCard(s.redirfilter,tp,LOCATION_ONFIELD,0,1,tc,re)
end

function s.redirfilter(c,re)
	return c:IsFaceup() and re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) and re:GetHandler():IsCanBeEffectTarget(re,c)
end

function s.redirop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	if not tg or #tg~=1 then return end
	local oldtc=tg:GetFirst()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectMatchingCard(tp,s.redirfilter,tp,LOCATION_ONFIELD,0,1,1,oldtc,re)
	if #g>0 then
		Duel.ChangeTargetCard(ev,g)
	end
end

-- Effect 2: Discard 1 to draw 2
function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,2,REASON_EFFECT)
end
