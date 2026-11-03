--Fiend's Aura Force Field
local s,id=GetID()
local CARD_FIEND_WARRING_TRIAD=89671216
local CARD_STATUE_OF_THE_GODS=89671213
s.listed_names={CARD_FIEND_WARRING_TRIAD,CARD_STATUE_OF_THE_GODS}
local CARD_TYPES={TYPE_MONSTER,TYPE_SPELL,TYPE_TRAP}
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--Special Summon "Fiend of the Warring Triad" from your Extra Deck (treated as properly Summoned), then attach 1 other face-up card on the field to it as material
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,{id,1})
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--Declare a card type; "Fiend of the Warring Triad" is unaffected by your opponent's cards of that type until the end of the turn
	--("Statue of the Gods": if the coin toss was tails, declare a 2nd type as well)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetTarget(s.imtg)
	e2:SetOperation(s.imop)
	c:RegisterEffect(e2)
end
--Special Summon + attach
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_FIEND_WARRING_TRIAD) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.ovfilter(c,ec)
	return c~=ec and c:IsFaceup() and not c:IsType(TYPE_TOKEN)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if sc and Duel.SpecialSummon(sc,0,tp,tp,true,false,POS_FACEUP)>0 then
		--treated as properly Summoned
		sc:CompleteProcedure()
		--(1 other face-up card: not the Fiend, and not this card either)
		local c=e:GetHandler()
		if sc:IsLocation(LOCATION_MZONE) and Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,sc,c) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local og=Duel.SelectMatchingCard(tp,s.ovfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,sc,c)
			if #og>0 then
				Duel.BreakEffect()
				Duel.Overlay(sc,og)
			end
		end
	end
end
--immunity
function s.fiendfilter(c)
	return c:IsFaceup() and c:IsCode(CARD_FIEND_WARRING_TRIAD)
end
function s.imtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.fiendfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CARDTYPE)
	--0: Monster, 1: Spell, 2: Trap
	e:SetLabel(Duel.SelectOption(tp,70,71,72))
end
function s.imop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local first=e:GetLabel()
	local mask=CARD_TYPES[first+1]
	--"Statue of the Gods": if the coin toss for this activation was tails, declare a 2nd card type as well
	if c:GetFlagEffectLabel(CARD_STATUE_OF_THE_GODS)==Duel.GetCurrentChain() then
		local others={}
		for i=0,2 do
			if i~=first then table.insert(others,i) end
		end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CARDTYPE)
		local second=others[Duel.SelectOption(tp,70+others[1],70+others[2])+1]
		mask=mask|CARD_TYPES[second+1]
	end
	--covers every "Fiend of the Warring Triad" you control, including one that arrives later this turn
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.fiendtg)
	e1:SetValue(s.efilter)
	e1:SetLabel(mask)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	--indicator: each Fiend on the field shows which card types it is unaffected by while hovered over
	local fg=Duel.GetMatchingGroup(s.fiendfilter,tp,LOCATION_MZONE,0,nil)
	for fc in fg:Iter() do
		for i=1,3 do
			if mask&CARD_TYPES[i]~=0 then
				local e2=Effect.CreateEffect(c)
				e2:SetDescription(aux.Stringid(id,i+1))
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_IMMUNE_EFFECT)
				e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
				e2:SetValue(s.efilter2)
				e2:SetLabel(CARD_TYPES[i])
				e2:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
				fc:RegisterEffect(e2)
			end
		end
	end
end
function s.efilter2(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActiveType(e:GetLabel())
end
function s.fiendtg(e,c)
	return c:IsFaceup() and c:IsCode(CARD_FIEND_WARRING_TRIAD)
end
function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetOwnerPlayer() and te:IsActiveType(e:GetLabel())
end
