--Surge Cannon
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCondition(s.condition)
    e1:SetCost(s.eqcost)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local opp=1-tp
	if Duel.GetTurnPlayer()==tp then
		-- Your turn: need at least 2 opponent's cards on field that can be destroyed
		return Duel.GetMatchingGroupCount(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil,tp,POS_FACEDOWN)>0
	else
		-- Opponent's turn: need at least 1 opponent's card on field that can be banished face-down
		return Duel.GetMatchingGroupCount(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)>=2
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local opp=1-tp
	if Duel.GetTurnPlayer()==tp then
		-- Your turn: destroy 2 opponent's cards (no targeting)
		local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil,tp,POS_FACEDOWN)
		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local sg=g:Select(tp,1,1,nil)
			Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)
		end
	else
		-- Opponent's turn: banish 1 opponent's card face-down (no targeting)
		local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
		if #g>=2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local sg=g:Select(tp,2,2,nil)
			Duel.Destroy(sg,REASON_EFFECT)
		end
	end
end
function s.eqcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,2,e:GetHandler()) end
	Duel.DiscardHand(tp,Card.IsDiscardable,2,2,REASON_COST|REASON_DISCARD)
end