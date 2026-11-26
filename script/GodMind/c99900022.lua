--GodMind Computer Superprocess (was "GodMind Calibrator" until 2026-11-22)
--Quick-Play Spell. Discard 1 card, then Tribute 1 Fusion, Synchro, Xyz, or Link Monster you control with "GodMind" in its ORIGINAL name
--(so a stolen / hijacked monster does not count; same idea as "GodMind Processing Universe");
--Special Summon 1 "GodMind Processor 10²" monster from your Extra Deck that is the same type (Fusion, Synchro, Xyz, Link) as the Tributed monster.
--(Changed 2026-11-25: it used to need a monster that has a Processor version and summoned exactly that version, via a UPGRADE table.)
--You can only activate 1 "GodMind Computer Superprocess" per turn.
--"GodMind Processor 10²" is a sub-archetype of "GodMind": setcode 0x3650 (strings.conf), so those monsters also count as "GodMind" (0x1650).
local s,id=GetID()
local SET_GODMIND=0x1650
local SET_PROCESSOR=0x3650
local EXTRA_TYPES=TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
--the Summon type used for an Extra Deck monster
function s.sumtype(c)
	if c:IsType(TYPE_FUSION) then return SUMMON_TYPE_FUSION end
	if c:IsType(TYPE_SYNCHRO) then return SUMMON_TYPE_SYNCHRO end
	if c:IsType(TYPE_XYZ) then return SUMMON_TYPE_XYZ end
	if c:IsType(TYPE_LINK) then return SUMMON_TYPE_LINK end
	return nil
end
--a Processor of the Summon type "st" (the type of the Tributed monster) in the Extra Deck that can be Summoned after the Tribute of tc (tc=nil once it is gone)
function s.spfilter(c,e,tp,st,tc)
	return c:IsSetCard(SET_PROCESSOR) and s.sumtype(c)==st
		and Duel.GetLocationCountFromEx(tp,tp,tc,c)>0 and c:IsCanBeSpecialSummoned(e,st,tp,false,false)
end
--only a face-up monster that is ORIGINALLY a "GodMind" monster, with a Processor of its type available in the Extra Deck, can be Tributed
function s.tribfilter(c,e,tp)
	return c:IsFaceup() and c:IsOriginalSetCard(SET_GODMIND) and c:IsType(EXTRA_TYPES) and c:IsReleasable()
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,s.sumtype(c),c)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,c)
			and Duel.IsExistingMatchingCard(s.tribfilter,tp,LOCATION_MZONE,0,1,nil,e,tp)
	end
	--discard 1 card, then Tribute 1 originally-"GodMind" Extra Deck monster you control; remember its Summon type
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST|REASON_DISCARD,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local tc=Duel.SelectMatchingCard(tp,s.tribfilter,tp,LOCATION_MZONE,0,1,1,nil,e,tp):GetFirst()
	e:SetLabel(s.sumtype(tc))
	Duel.Release(tc,REASON_COST)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local st=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,st,nil):GetFirst()
	if sc then
		if Duel.SpecialSummon(sc,st,tp,tp,false,false,POS_FACEUP)>0 then
			--treated as properly Summoned
			sc:CompleteProcedure()
		end
	end
end
