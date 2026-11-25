--GodMind Processor 10² StarWare   (upgraded Pendulum version of "GodMind StarWare"; Link-4, Pendulum Scale 2)   REDESIGNED 2026-11-22
--[ Pendulum Effect ] During your Main Phase: You can Special Summon 1 monster from your opponent's GY or banishment to your field, ignoring its Summoning conditions, and if you do, it is hijacked.
--  You can only use this effect of "GodMind Processor 10² StarWare" once per turn.
--[ Monster Effect ] 2+ "GodMind" monsters, including a "GodMind" Link Monster
--  If you can Pendulum Summon Level 8, you can Pendulum Summon this face-up card in your Extra Deck.
--  (Quick Effect, once per turn, DOES NOT TARGET): negate the effects of 1 face-up monster, or 1 face-up Spell/Trap Card, your opponent controls (if it is a Spell/Trap Card being activated,
--  also negate that activation), then take control of it (a Continuous Spell/Trap or Field Spell is moved to your S/T Zone or Field Zone; any other Spell/Trap Card is Set in your S/T Zone),
--  and if you do, its effects are no longer negated, also it is hijacked (+ LIGHT / Machine, or Cyberse for an Extra Deck monster).
--The card is chosen on resolution (no targeting). When this effect responds to a Normal / Quick-Play Spell or a Normal / Counter Trap being activated, that card is still on the field and on the chain,
--so it can be chosen, its chain link is negated, and it ends up Set on your side, hijacked.
local s,id=GetID()
local SET_GODMIND=0x1650
local starware=Duel.LoadCardScript(99900011)
--Extra Deck Pendulum Monsters have no Level for the Pendulum Summon: proc_pendulum.lua reads this field
s.pendulum_level=8
function s.initial_effect(c)
	c:EnableReviveLimit()
	--must first be properly Summoned (or Pendulum Summoned, or Special Summoned by its own effect), or Special Summoned by "GodMind Computer Superprocess"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	--Link Summon: 2+ "GodMind" monsters, including a "GodMind" Link Monster
	Link.AddProcedure(c,starware.matfilter,2,99,s.lcheck)
	Pendulum.AddProcedure(c,false)
	--Pendulum Effect: Special Summon 1 monster from your opponent's GY or banishment, ignoring its Summoning conditions; hijack it
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,1))
	e0:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e0:SetType(EFFECT_TYPE_IGNITION)
	e0:SetRange(LOCATION_PZONE)
	e0:SetCountLimit(1,{id,1})
	e0:SetTarget(s.pstg)
	e0:SetOperation(s.psop)
	c:RegisterEffect(e0)
	--Quick Effect, once per turn, no target: negate + take control (a Spell/Trap that is being activated is Set instead)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_CONTROL+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
function s.linkmat(c,lc,sumtype,tp)
	return c:IsType(TYPE_LINK,lc,sumtype,tp) and c:IsSetCard(SET_GODMIND,lc,sumtype,tp)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(s.linkmat,1,nil,lc,sumtype,tp)
end
---------------------------------------------------------------------------------------------------------------------
--Pendulum Effect: Special Summon 1 monster from your opponent's GY or banishment (ignoring its Summoning conditions), hijacked
function s.psfilter(c,e,tp)
	--this Summon ignores Summoning conditions, so the "GodMind Processor 10²" monsters (setcode 0x3650) are excluded by hand: they may only
	--be Summoned by their own procedure, a Pendulum Summon or "GodMind Computer Superprocess"
	return c:IsMonster() and not c:IsSetCard(0x3650) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.pstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.psfilter),tp,0,LOCATION_GRAVE|LOCATION_REMOVED,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,1-tp,LOCATION_GRAVE|LOCATION_REMOVED)
end
function s.psop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.psfilter),tp,0,LOCATION_GRAVE|LOCATION_REMOVED,1,1,nil,e,tp):GetFirst()
	if tc then
		--hijacked BEFORE it is Summoned (its own "when Special Summoned" trigger must be the rewritten one), LIGHT + Machine / Cyberse
		starware.hijack(c,tc)
		starware.lightform(c,tc)
		Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)
	end
end
---------------------------------------------------------------------------------------------------------------------
--Monster Effect (no target): the card is chosen on resolution from the cards your opponent controls
--  monster: face-up and its control can be changed; Field Spell: face-up; any other face-up Spell/Trap (Continuous, or a Normal / Quick-Play /
--  Counter card that is being activated): needs a free Spell & Trap Zone
--is this Spell/Trap Card being activated, with its chain link still waiting to resolve?
function s.pending(c)
	for i=1,Duel.GetCurrentChain() do
		local te=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT)
		if te and te:GetHandler()==c and te:IsHasType(EFFECT_TYPE_ACTIVATE) then return true end
	end
	return false
end
function s.filter(c,tp)
	if not c:IsFaceup() then return false end
	if c:IsMonster() then return c:IsControlerCanBeChanged() end
	if c:IsType(TYPE_FIELD) then return true end
	--Continuous Spell/Trap, or any Spell/Trap Card that is being activated
	return c:IsSpellTrap() and (c:IsType(TYPE_CONTINUOUS) or s.pending(c)) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,0,LOCATION_ONFIELD,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local tc=Duel.SelectMatchingCard(tp,s.filter,tp,0,LOCATION_ONFIELD,1,1,nil,tp):GetFirst()
	if not tc then return end
	Duel.HintSelection(tc)
	--negate its effects...
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e2)
	--A Normal / Quick-Play Spell or Normal / Counter Trap that is being activated: its effects stay negated, so when its chain link resolves
	--it resolves as negated; it is kept from going to the GY (Card.CancelToGrave) and, once its link has resolved, it is Set on your side and hijacked.
	if tc:IsSpellTrap() and not tc:IsType(TYPE_FIELD|TYPE_CONTINUOUS) and s.pending(tc) then
		tc:CancelToGrave()
		local fid=tc:GetFieldID()
		local ec=Effect.CreateEffect(c)
		ec:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ec:SetCode(EVENT_CHAIN_SOLVED)
		ec:SetCondition(function(e_,tp_,eg_,ep_,ev_,re_) return re_~=nil and re_:GetHandler()==tc end)
		ec:SetOperation(function(e_,tp_)
			e_:Reset()
			if not (tc:IsOnField() and tc:GetFieldID()==fid and tc:IsFaceup()) then
				e1:Reset() e2:Reset()
				return
			end
			if Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
				Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
			end
			e1:Reset() e2:Reset()
			if tc:IsControler(tp) then
				starware.hijack(c,tc)
			end
		end)
		ec:SetReset(RESET_CHAIN)
		Duel.RegisterEffect(ec,tp)
		return
	end
	--...then take control of it
	if tc:IsMonster() then
		Duel.GetControl(tc,tp)
	elseif tc:IsType(TYPE_FIELD) then
		local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
		if fc then
			Duel.SendtoGrave(fc,REASON_RULE)
			Duel.BreakEffect()
		end
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
	elseif tc:IsType(TYPE_CONTINUOUS) then
		if Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		end
	end
	if not tc:IsControler(tp) then return end
	--the negation of its effects ends once it is on your field
	e1:Reset()
	e2:Reset()
	--hijack it, and a monster becomes LIGHT and Machine / Cyberse
	starware.hijack(c,tc)
	starware.lightform(c,tc)
end

--Summoning condition: only by its own Summon procedure (LINK Summon), a Pendulum Summon, its own effect, or "GodMind Computer Superprocess" (99900022)
function s.splimit(e,se,sp,st)
	if se then
		local sc=se:GetHandler()
		if sc==e:GetHandler() or sc:GetOriginalCode()==99900022 then return true end
	end
	return (st&SUMMON_TYPE_LINK)==SUMMON_TYPE_LINK or (st&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end
