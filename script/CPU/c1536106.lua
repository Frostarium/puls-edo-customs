--CPU Fail Shock
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
	e1:SetCost(s.cost)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsNegatable),tp,0,LOCATION_ONFIELD,1,nil)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsNegatable),tp,0,LOCATION_ONFIELD,nil)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local sg=g:Select(tp,1,1,nil)
	local tc=sg:GetFirst()
	if tc and s.negate(tc) then
		-- Schedule banish at End Phase if still on field
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetLabelObject(tc)
		e1:SetCondition(s.rmcon)
		e1:SetOperation(s.rmop)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

function s.negate(tc)
	if not tc or not tc:IsFaceup() or tc:IsDisabled() then return false end
	local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetValue(RESET_TURN_SET)
			e2:SetReset(RESETS_STANDARD)
			tc:RegisterEffect(e2)
	return true
end

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	return tc and tc:IsOnField() and tc:IsFaceup()
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc and tc:IsOnField() and tc:IsFaceup() then
		Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
	end
end
