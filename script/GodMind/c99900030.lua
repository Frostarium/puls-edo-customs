--GodMind Observation (was "GodMind Boot Sequence" until 2026-11-22)
--Normal Spell. Activate 1 of these effects (but you can only use each effect of "GodMind Observation" once per turn):
--● Discard 1 card, then activate 1 "GodMind Processing Universe" from your Deck.
--● Shuffle 1 Spell/Trap on the field into the Deck.
--● Special Summon 1 "GodMind" monster from your GY or banishment.
local s,id=GetID()
local SET_GODMIND=0x1650
local CODE_PU=99900010
--per-effect once-per-turn flags (the choice is made at activation)
function s.flag(n) return id*10+n end
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.pufilter(c,tp)
	return c:IsCode(CODE_PU) and c:GetActivateEffect() and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.tdfilter(c)
	return c:IsSpellTrap() and c:IsAbleToDeck()
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_GODMIND) and c:IsMonster() and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=Duel.GetFlagEffect(tp,s.flag(1))==0
		and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,c)
		and Duel.IsExistingMatchingCard(s.pufilter,tp,LOCATION_DECK,0,1,nil,tp)
	local b2=Duel.GetFlagEffect(tp,s.flag(2))==0
		and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,c)
	local b3=Duel.GetFlagEffect(tp,s.flag(3))==0
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil,e,tp)
	if chk==0 then return b1 or b2 or b3 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,0)},
		{b2,aux.Stringid(id,1)},
		{b3,aux.Stringid(id,2)})
	e:SetLabel(op)
	Duel.RegisterFlagEffect(tp,s.flag(op),RESET_PHASE|PHASE_END,0,1)
	if op==1 then
		e:SetCategory(CATEGORY_HANDES)
		Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
	elseif op==2 then
		e:SetCategory(CATEGORY_TODECK)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,PLAYER_ALL,LOCATION_ONFIELD)
	else
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==1 then
		--Discard 1 card, then activate 1 "GodMind Processing Universe" from your Deck
		if Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT|REASON_DISCARD,nil)>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
			local tc=Duel.SelectMatchingCard(tp,s.pufilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
			if tc then
				Duel.ActivateFieldSpell(tc,e,tp,eg,ep,ev,re,r,rp)
			end
		end
	elseif op==2 then
		--Shuffle 1 Spell/Trap on the field into the Deck
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,e:GetHandler())
		if #g>0 then
			Duel.HintSelection(g,true)
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	else
		--Special Summon 1 "GodMind" monster from your GY or banishment
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end
