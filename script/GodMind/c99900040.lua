--GodMind Processor 10² StarWare   (upgraded Pendulum version of "GodMind StarWare"; Link-4, Pendulum Scale 2)   REDESIGNED 2026-11-22
--[ Pendulum Effect ] During your Main Phase: You can Special Summon 1 monster from your opponent's GY or banishment to your field, ignoring its Summoning conditions, and if you do, it is hijacked.
--  You can only use this effect of "GodMind Processor 10² StarWare" once per turn.
--[ Monster Effect ] 2+ "GodMind" monsters, including a "GodMind" Link Monster
--  If you can Pendulum Summon Level 8, you can Pendulum Summon this face-up card in your Extra Deck.
--  (2 Ignition Effects sharing one use per turn, DO NOT TARGET), CHANGED 2026-11-25: choose on resolution 1 face-up monster / face-up Continuous Spell/Trap / face-up Field Spell
--  (negate its effects, take control), 1 Set Spell/Trap your opponent controls (take control, it stays Set), or 1 Spell/Trap in your opponent's GY (Set it on your side);
--  then it is hijacked (+ LIGHT / Machine, or Cyberse for an Extra Deck monster). It no longer steals Normal / Quick-Play Spells or Normal / Counter Traps that are being activated.
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
	--Ignition Effect 1 (no target): negate + take control of a monster.
	--Ignition Effect 2 (no target): negate + take control of backrow cards / Set a Spell/Trap from the GY.
	--(2026-11-25: not Quick Effects; with "GodMind Processing Universe" face-up they get Quick clones like every other Extra Deck GodMind)
	--(split in two on 2026-11-25 for readability; each has its own once-per-turn (1,id) and (1,{id,2}) since 2026-11-25)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_CONTROL+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.montg)
	e1:SetOperation(s.monop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_CONTROL+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.sttg)
	e2:SetOperation(s.stop)
	c:RegisterEffect(e2)
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
--Ignition Effects (no target): the card is chosen on resolution from the cards your opponent controls (or their GY)
--  Effect 1: a face-up monster in the Monster Zone whose control can be changed -> negated, control taken, hijacked, LIGHT + Machine / Cyberse
--  Effect 2 (no longer steals Normal / Quick-Play Spells or Normal / Counter Traps that are being activated, 2026-11-25):
--    a) a face-up Field Spell, or face-up Continuous Spell/Trap -> negated, moved face-up to your Field Zone / S&T Zone
--    b) a face-down Spell/Trap on the field                     -> moved to your Field Zone / S&T Zone, staying face-down
--    c) a Spell/Trap in the opponent's GY                       -> Set on your side
--  all of them are hijacked afterwards
function s.monfilter(c,tp)
	return c:IsFaceup() and c:IsMonster() and c:IsLocation(LOCATION_MZONE) and c:IsControlerCanBeChanged()
end
function s.stfilter(c,tp)
	if c:IsLocation(LOCATION_GRAVE) then
		return c:IsSpellTrap() and c:IsSSetable(true) and (c:IsType(TYPE_FIELD) or Duel.GetLocationCount(tp,LOCATION_SZONE)>0)
	end
	if c:IsFacedown() then
		return c:IsSpellTrap() and (c:IsType(TYPE_FIELD) or Duel.GetLocationCount(tp,LOCATION_SZONE)>0)
	end
	if c:IsMonster() then return false end
	if c:IsType(TYPE_FIELD) then return true end
	return c:IsSpellTrap() and c:IsType(TYPE_CONTINUOUS) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
end
--negate the effects of a face-up card until it is on your side (the returned effects are reset by the caller)
function s.negate(c,tc)
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
	return e1,e2
end
--Effect 1: monsters
function s.montg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.monfilter,tp,0,LOCATION_MZONE,1,nil,tp) end
	Duel.SetPossibleOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_MZONE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_CONTROL,nil,1,1-tp,LOCATION_MZONE)
end
function s.monop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local tc=Duel.SelectMatchingCard(tp,s.monfilter,tp,0,LOCATION_MZONE,1,1,nil,tp):GetFirst()
	if not tc then return end
	Duel.HintSelection(tc)
	local e1,e2=s.negate(c,tc)
	Duel.GetControl(tc,tp)
	if not tc:IsControler(tp) then return end
	--the negation of its effects ends once it is on your field
	e1:Reset()
	e2:Reset()
	--hijack it, and it becomes LIGHT and Machine / Cyberse
	starware.hijack(c,tc)
	starware.lightform(c,tc)
end
--Effect 2: backrow
function s.sttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.stfilter),tp,0,LOCATION_ONFIELD|LOCATION_GRAVE,1,nil,tp) end
	Duel.SetPossibleOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_ONFIELD)
	Duel.SetPossibleOperationInfo(0,CATEGORY_CONTROL,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.stop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.stfilter),tp,0,LOCATION_ONFIELD|LOCATION_GRAVE,1,1,nil,tp):GetFirst()
	if not tc then return end
	Duel.HintSelection(tc)
	--c) a Spell/Trap from the opponent's GY: Set on your side, then hijacked
	if tc:IsLocation(LOCATION_GRAVE) then
		if Duel.SSet(tp,tc,tp)>0 and tc:IsLocation(LOCATION_ONFIELD) and tc:IsControler(tp) then
			starware.hijack(c,tc)
		end
		return
	end
	--b) a face-down Spell/Trap: moved to your side, staying face-down (nothing to negate), then hijacked
	if tc:IsFacedown() then
		if tc:IsType(TYPE_FIELD) then
			local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
			if fc then
				Duel.SendtoGrave(fc,REASON_RULE)
				Duel.BreakEffect()
			end
			Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEDOWN,true)
		else
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
		end
		if tc:IsControler(tp) then
			starware.hijack(c,tc)
		end
		return
	end
	--a) a face-up Field Spell / Continuous Spell/Trap: negate its effects, then take control of it
	local e1,e2=s.negate(c,tc)
	if tc:IsType(TYPE_FIELD) then
		local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
		if fc then
			Duel.SendtoGrave(fc,REASON_RULE)
			Duel.BreakEffect()
		end
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
	elseif Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
	if not tc:IsControler(tp) then return end
	e1:Reset()
	e2:Reset()
	starware.hijack(c,tc)
end
--Summoning condition: only by its own Summon procedure (LINK Summon), a Pendulum Summon, its own effect, or "GodMind Computer Superprocess" (99900022)
function s.splimit(e,se,sp,st)
	if se then
		local sc=se:GetHandler()
		if sc==e:GetHandler() or sc:GetOriginalCode()==99900022 then return true end
	end
	return (st&SUMMON_TYPE_LINK)==SUMMON_TYPE_LINK or (st&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end
