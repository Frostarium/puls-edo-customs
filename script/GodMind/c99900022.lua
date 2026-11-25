--GodMind Computer Superprocess (was "GodMind Calibrator" until 2026-11-22)
--Quick-Play Spell. Discard 1 card, then Tribute 1 "GodMind" Fusion, Synchro, Xyz, or Link Monster Card you control;
--Special Summon 1 "GodMind Processor 10²" monster of the same type (Fusion, Synchro, Xyz, Link) from your Extra Deck, whose name is the Tributed monster's name with "Processor 10²" added after "GodMind"
--(wording modelled on "Dunamis Magistus", 100462028)
--(= the Processor version of the Tributed monster; UPGRADE below). A monster with no Processor version in your Extra Deck cannot be chosen.
--(This Special Summon is treated as a Fusion Summon, Synchro Summon, Xyz Summon, or Link Summon, respectively.)
--You can only activate 1 "GodMind Computer Superprocess" per turn.
--"GodMind Processor 10²" is a sub-archetype of "GodMind": setcode 0x3650 (strings.conf), so those monsters also count as "GodMind" (0x1650).
local s,id=GetID()
local SET_GODMIND=0x1650
local EXTRA_TYPES=TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK
--base monster (original code) -> its Processor version (original code)
local UPGRADE={
	[99900011]=99900040, --GodMind StarWare       -> GodMind Processor 10² StarWare
	[99900012]=99900041, --GodMind SuIntelligence -> GodMind Processor 10² SuIntelligence
	[99900013]=99900042, --GodMind Technarch      -> GodMind Processor 10² Technarch
	[99900015]=99900043, --GodMind Shi'arWare     -> GodMind Processor 10² Shi'arWare
}
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
--the Processor version (code "code") of the Tributed monster, in the Extra Deck, that can be Summoned after the Tribute of tc (tc=nil once it is gone)
function s.spfilter(c,e,tp,code,tc)
	local st=s.sumtype(c)
	if not st or not c:IsOriginalCode(code) then return false end
	return Duel.GetLocationCountFromEx(tp,tp,tc,c)>0 and c:IsCanBeSpecialSummoned(e,st,tp,false,false)
end
--only a monster that HAS a Processor version, with that version available in the Extra Deck, can be Tributed
function s.tribfilter(c,e,tp)
	local code=UPGRADE[c:GetOriginalCode()]
	return code~=nil and c:IsFaceup() and c:IsSetCard(SET_GODMIND) and c:IsType(EXTRA_TYPES) and c:IsReleasable()
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,code,c)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,c)
			and Duel.IsExistingMatchingCard(s.tribfilter,tp,LOCATION_MZONE,0,1,nil,e,tp)
	end
	--discard 1 card, then Tribute 1 "GodMind" Extra Deck monster you control that has a Processor version
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST|REASON_DISCARD,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local tc=Duel.SelectMatchingCard(tp,s.tribfilter,tp,LOCATION_MZONE,0,1,1,nil,e,tp):GetFirst()
	e:SetLabel(UPGRADE[tc:GetOriginalCode()])
	Duel.Release(tc,REASON_COST)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,code,nil):GetFirst()
	if sc then
		if Duel.SpecialSummon(sc,s.sumtype(sc),tp,tp,false,false,POS_FACEUP)>0 then
			--treated as properly Summoned
			sc:CompleteProcedure()
		end
	end
end
