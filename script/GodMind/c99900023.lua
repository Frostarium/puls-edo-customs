--GodMind Warzone (replaced "GodMind Firewall" on 2026-11-22)
--Continuous Trap.
--If you control a "GodMind" Fusion, Synchro, Xyz, or Link Monster (Quick Effect): You can target 1 monster your opponent controls; negate its effects until the end of this turn,
--and if you do, it cannot leave the field until the End Phase, also, during the End Phase of this turn, return it to the hand. You can only use this effect of "GodMind Warzone" once per turn.
--(s.lockonfield is also used by "GodMind Processor 10² Technarch".)
--"GodMind" Fusion, Synchro, Xyz, and Link Monsters you control cannot be targeted by your opponent's card effects.
local s,id=GetID()
local SET_GODMIND=0x1650
local EXTRA_TYPES=TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--Negate 1 monster your opponent controls, lock it on the field, return it to the hand in the End Phase
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--Your "GodMind" Extra Deck monsters cannot be targeted by your opponent's card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.edfilter)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
end
function s.edfilter(e,c)
	return c:IsSetCard(SET_GODMIND) and c:IsType(EXTRA_TYPES)
end
function s.gmfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_GODMIND) and c:IsType(EXTRA_TYPES)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.gmfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
--"tc cannot leave the field until the End Phase" (effect owner c). Every lock stops applying once the End Phase starts,
--so from then on any card can make it leave. Covers: sent to hand / Deck / GY, banished, destroyed, Tributed, used as material.
function s.notendphase()
	return Duel.GetCurrentPhase()~=PHASE_END
end
function s.lockonfield(c,tc)
	local locks={
		{EFFECT_CANNOT_TO_HAND},
		{EFFECT_CANNOT_TO_DECK},
		{EFFECT_CANNOT_REMOVE},
		{EFFECT_CANNOT_TO_GRAVE},
		{EFFECT_INDESTRUCTABLE_BATTLE,1},
		{EFFECT_INDESTRUCTABLE_EFFECT,1},
		{EFFECT_UNRELEASABLE_SUM,1},
		{EFFECT_UNRELEASABLE_NONSUM,1},
		{EFFECT_CANNOT_BE_MATERIAL,aux.cannotmatfilter(SUMMON_TYPE_FUSION,SUMMON_TYPE_SYNCHRO,SUMMON_TYPE_XYZ,SUMMON_TYPE_LINK)},
	}
	for _,lock in ipairs(locks) do
		local el=Effect.CreateEffect(c)
		el:SetType(EFFECT_TYPE_SINGLE)
		el:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		el:SetCode(lock[1])
		if lock[2] then el:SetValue(lock[2]) end
		el:SetCondition(s.notendphase)
		el:SetReset(RESETS_STANDARD_PHASE_END)
		tc:RegisterEffect(el)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:IsControler(1-tp)) then return end
	--negate its effects until the end of this turn
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(RESETS_STANDARD_PHASE_END)
	tc:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	e2:SetReset(RESETS_STANDARD_PHASE_END)
	tc:RegisterEffect(e2)
	if tc:IsType(TYPE_TRAPMONSTER) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
		e3:SetReset(RESETS_STANDARD_PHASE_END)
		tc:RegisterEffect(e3)
	end
	--it cannot leave the field until the End Phase
	s.lockonfield(c,tc)
	--during the End Phase of this turn, return it to the hand
	local fid=tc:GetFieldID()
	local ep1=Effect.CreateEffect(c)
	ep1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ep1:SetCode(EVENT_PHASE+PHASE_END)
	ep1:SetCountLimit(1)
	ep1:SetLabelObject(tc)
	ep1:SetOperation(function(e2_,tp2)
		local rc=e2_:GetLabelObject()
		if rc and rc:GetFieldID()==fid and rc:IsOnField() and rc:IsAbleToHand() then
			Duel.SendtoHand(rc,nil,REASON_EFFECT)
		end
	end)
	ep1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(ep1,tp)
end
