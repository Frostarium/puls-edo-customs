--Kefka The God of Magic
local s,id=GetID()
local CARD_GODDESS_WARRING_TRIAD=89671211
local CARD_POLTRGEIST_WARRING_TRIAD=89671215
local CARD_FIEND_WARRING_TRIAD=89671216
local CARD_KEFKA_MASTER_WARRING_TRIAD=89671214
local CARD_STATUE_OF_THE_GODS=89671213
local CARD_LIGHT_OF_JUDGMENT=89671221
s.listed_names={CARD_GODDESS_WARRING_TRIAD,CARD_POLTRGEIST_WARRING_TRIAD,CARD_FIEND_WARRING_TRIAD,CARD_KEFKA_MASTER_WARRING_TRIAD,CARD_STATUE_OF_THE_GODS,CARD_LIGHT_OF_JUDGMENT}
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Summon procedure: banish "Goddess", "Poltrgeist" and "Fiend of the Warring Triad" and "Kefka Master of the Warring Triad" from your field and/or GY
	Fusion.AddProcMix(c,true,true,CARD_GODDESS_WARRING_TRIAD,CARD_POLTRGEIST_WARRING_TRIAD,CARD_FIEND_WARRING_TRIAD,CARD_KEFKA_MASTER_WARRING_TRIAD)
	Fusion.AddContactProc(c,s.contactfil,s.contactop,s.splimit,s.contactcon)
	Pendulum.AddProcedure(c,false)
	--Cannot be targeted by your opponent's card effects
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e0:SetValue(aux.tgoval)
	c:RegisterEffect(e0)
	--Quick Effect: place this card in your Pendulum Zone, and if you do, all monsters your opponent controls become 1 ATK/DEF and have their effects negated until the end of this turn
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--The first time this card would be destroyed by battle or card effect, you can banish 1 other card on the field face-down instead
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTarget(s.reptg)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)
	--Pendulum Effect: Tribute 1 monster you control; Special Summon this card from your Pendulum Zone, and if you do, during the next Standby Phase your opponent sends all monsters they control to the GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
--destruction replacement: take control of 1 of your opponent's monsters, which becomes a Zombie
function s.rmfilter(c)
	return c:IsAbleToRemove(nil,POS_FACEDOWN)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return not c:IsReason(REASON_REPLACE) and c:IsReason(REASON_BATTLE|REASON_EFFECT) and not c:HasFlagEffect(id)
			and Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,c)
	end
	return Duel.SelectEffectYesNo(tp,c,96)
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--only the first time it would be destroyed (while it stays on the field)
	c:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,0,1)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,c)
	if #g>0 then
		Duel.HintSelection(g,true)
		Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
	end
end
--Pendulum Effect
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	--"Light of Judgment" replaces this cost permanently (see its script)
	if chk==0 then return not e:GetHandler():HasFlagEffect(CARD_LIGHT_OF_JUDGMENT) and Duel.CheckReleaseGroupCost(tp,nil,1,false,aux.ReleaseCheckMMZ,nil) end
	local rg=Duel.SelectReleaseGroupCost(tp,nil,1,1,false,aux.ReleaseCheckMMZ,nil)
	Duel.Release(rg,REASON_COST)
end
--"Spell Speed 4": the engine only has Spell Speeds 1-3, so it is emulated: once one of this card's effects is activated,
--only another effect of this card can be chained to it (the activating effect itself can still be chained to Spell Speed 1 and 2 effects)
function s.chlimit(e,ep,tp)
	return e:GetHandler():IsOriginalCode(id)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsCanBeSpecialSummoned(e,0,tp,true,false) end
	Duel.SetChainLimit(s.chlimit)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_PZONE)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,0,1-tp,LOCATION_MZONE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)==0 then return end
	--...and it gains 3000 ATK/DEF
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(3000)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)
	--during the next Standby Phase (either player's), your opponent sends all monsters they control to the GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetCountLimit(1)
	e1:SetOperation(s.gyop)
	e1:SetReset(RESET_PHASE|PHASE_STANDBY)
	Duel.RegisterEffect(e1,tp)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	local g=Duel.GetFieldGroup(1-tp,LOCATION_MZONE,0)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end
--contact Fusion: banish the 3 materials from the field or GY
function s.contactfil(tp)
	return Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE|LOCATION_GRAVE,0,nil)
end
function s.matfilter(c)
	return (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToRemoveAsCost()
end
--...and only while you control "Statue of the Gods"
function s.statuefilter(c)
	return c:IsFaceup() and c:IsCode(CARD_STATUE_OF_THE_GODS)
end
function s.contactcon(tp)
	return Duel.IsExistingMatchingCard(s.statuefilter,tp,LOCATION_ONFIELD,0,1,nil)
end
function s.contactop(g)
	Duel.Remove(g,POS_FACEUP,REASON_COST|REASON_MATERIAL)
end
function s.splimit(e,se,sp,st)
	return not e:GetHandler():IsLocation(LOCATION_EXTRA|LOCATION_GRAVE)
end
--Pendulum Zone + debuff
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp) end
	Duel.SetChainLimit(s.chlimit)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,0,1-tp,LOCATION_MZONE)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and Duel.CheckPendulumZones(tp)) then return end
	if not (Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true) and c:IsLocation(LOCATION_PZONE)) then return end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	for tc in g:Iter() do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		tc:RegisterEffect(e1)
		if not tc:IsType(TYPE_LINK) then
			local e2=e1:Clone()
			e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
			tc:RegisterEffect(e2)
		end
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_DISABLE)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		tc:RegisterEffect(e3)
		local e4=e3:Clone()
		e4:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e4)
	end
end
