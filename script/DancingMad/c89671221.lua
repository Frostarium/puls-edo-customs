--Light of Judgment
local s,id=GetID()
local CARD_KEFKA_MASTER_WARRING_TRIAD=89671214
local CARD_KEFKA_GOD_OF_MAGIC=89671219
s.listed_names={CARD_KEFKA_MASTER_WARRING_TRIAD,CARD_KEFKA_GOD_OF_MAGIC}
function s.initial_effect(c)
	--Activate 1 of these effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
--effect 1: Special Summon a "Kefka" monster
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_KEFKA_MASTER_WARRING_TRIAD,CARD_KEFKA_GOD_OF_MAGIC) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
		--"Kefka The God of Magic" must be Special Summoned by its own procedure, so its Summoning conditions are ignored
		and c:IsCanBeSpecialSummoned(e,0,tp,c:IsCode(CARD_KEFKA_GOD_OF_MAGIC),false)
		and ((c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0)
			or (not c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0))
end
--effect 2: a "Kefka The God of Magic" you control (in the Monster Zone or Pendulum Zone) that has not been given these effects yet
function s.godfilter(c)
	return c:IsFaceup() and c:IsCode(CARD_KEFKA_GOD_OF_MAGIC) and not c:HasFlagEffect(id)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_EXTRA,0,1,nil,e,tp)
	local b2=Duel.IsExistingMatchingCard(s.godfilter,tp,LOCATION_MZONE|LOCATION_PZONE,0,1,nil)
	if chk==0 then return b1 or b2 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,0)},
		{b2,aux.Stringid(id,1)})
	e:SetLabel(op)
	if op==1 then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_EXTRA)
	else
		e:SetCategory(0)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if e:GetLabel()==1 then
		--Special Summon 1 "Kefka" monster from your GY, banishment or face-up Extra Deck; it is unaffected by your opponent's card effects
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
		if tc and Duel.SpecialSummonStep(tc,0,tp,tp,tc:IsCode(CARD_KEFKA_GOD_OF_MAGIC),false,POS_FACEUP) then
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(aux.Stringid(id,2))
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_IMMUNE_EFFECT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
			e1:SetValue(s.immval)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
		Duel.SpecialSummonComplete()
	else
		--Give those effects to 1 "Kefka The God of Magic" you control (does not target); the changes are permanent
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
		local tc=Duel.SelectMatchingCard(tp,s.godfilter,tp,LOCATION_MZONE|LOCATION_PZONE,0,1,1,nil):GetFirst()
		if tc then
			Duel.HintSelection(tc,true)
			s.grant(c,tc)
		end
	end
end
function s.immval(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
--the permanent changes
function s.grant(c,tc)
	--(also read by the card's own Pendulum Effect, which can no longer be activated by Tributing)
	tc:RegisterFlagEffect(id,0,0,1)
	--If this card attacks: you can reduce your opponent's LP to 1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCondition(s.lpcon)
	e1:SetOperation(s.lpop)
	tc:RegisterEffect(e1,true)
	--Pendulum Effect: instead of Tributing 1 monster, Special Summon 1 monster from either GY or banishment to your field as a Zombie.
	--It shares its once per turn with the card's own Pendulum Effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,4))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,{CARD_KEFKA_GOD_OF_MAGIC,1})
	e2:SetCost(s.zcost)
	e2:SetTarget(s.zsptg)
	e2:SetOperation(s.zspop)
	tc:RegisterEffect(e2,true)
	--Tribute 1 monster you control; banish all cards in your opponent's GY face-down
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,5))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.bncost)
	e3:SetTarget(s.bntg)
	e3:SetOperation(s.bnop)
	tc:RegisterEffect(e3,true)
end
function s.bncost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,nil,1,false,nil,c) end
	local rg=Duel.SelectReleaseGroupCost(tp,nil,1,1,false,nil,c)
	Duel.Release(rg,REASON_COST)
end
function s.bnfilter(c)
	return c:IsAbleToRemove(nil,POS_FACEDOWN)
end
function s.bntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.bnfilter,tp,0,LOCATION_GRAVE,1,nil) end
	local g=Duel.GetMatchingGroup(s.bnfilter,tp,0,LOCATION_GRAVE,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,1-tp,LOCATION_GRAVE)
end
function s.bnop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.bnfilter,tp,0,LOCATION_GRAVE,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
	end
end
function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetAttacker()==e:GetHandler() and Duel.GetLP(1-tp)>1
end
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.SetLP(1-tp,1)
end
function s.zfilter(c,e,tp)
	return c:IsMonster() and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
--2 free zones: 1 for the monster, 1 for this card
function s.zcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
			and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.zfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,LOCATION_GRAVE|LOCATION_REMOVED,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.zfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,LOCATION_GRAVE|LOCATION_REMOVED,1,1,nil,e,tp):GetFirst()
	if tc and Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
		--Zombie
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_RACE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(RACE_ZOMBIE)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
	Duel.SpecialSummonComplete()
end
--the rest of the effect is the card's own (see its script)
function s.zsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	return _G["c"..CARD_KEFKA_GOD_OF_MAGIC].sptg(e,tp,eg,ep,ev,re,r,rp,chk)
end
function s.zspop(e,tp,eg,ep,ev,re,r,rp)
	return _G["c"..CARD_KEFKA_GOD_OF_MAGIC].spop(e,tp,eg,ep,ev,re,r,rp)
end
