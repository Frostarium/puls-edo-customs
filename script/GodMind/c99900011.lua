--GodMind StarWare
local s,id=GetID()
local SET_GODMIND=0x1650
--TEMPORARY DEBUG OUTPUT (set to false to silence): messages are printed with Debug.Message, prefix "[GodMind]"
local DEBUG=false
local dbgcount=0
local function dbg(msg)
	if DEBUG then Debug.Message("[GodMind] "..tostring(msg)) end
end
local function dbglimited(msg,limit)
	dbgcount=dbgcount+1
	if dbgcount<=(limit or 40) then dbg(msg) end
end
local wrappedeffects=setmetatable({},{__mode="k"}) --effect -> true once its functions have been wrapped
--describes an effect for the debug output
local function describe(te)
	if not te then return "nil" end
	local ok,res=pcall(function()
		return "owner="..tostring(te:GetOwner():GetOriginalCode())..", handler="..tostring(te:GetHandler():GetOriginalCode())
			..", type="..tostring(te:GetType())..", code="..tostring(te:GetCode())
			..", cond="..tostring(te:GetCondition()~=nil)..", tg="..tostring(te:GetTarget()~=nil)..", op="..tostring(te:GetOperation()~=nil)
			..", wrapped="..tostring(wrappedeffects[te]==true)
	end)
	return ok and res or ("(could not describe: "..tostring(res)..")")
end
--debug: report every card draw together with the effect that caused it
if DEBUG then
	local o_Draw=Duel.Draw
	Duel.Draw=function(p,ct,reason)
		local te=Duel.GetChainInfo(0,CHAININFO_TRIGGERING_EFFECT)
		dbg("Duel.Draw("..tostring(p)..","..tostring(ct)..") caused by effect: "..describe(te))
		if debug and debug.traceback then dbg(debug.traceback("draw call stack",2)) end
		return o_Draw(p,ct,reason)
	end
end
function s.initial_effect(c)
	--Link Summon: 2+ "GodMind" monsters
	Link.AddProcedure(c,s.matfilter,2,99)
	--Ignition Effect. Target 1 face-up card your opponent controls: negate it, take control of it (the negation ends), treat it as
	--GodMind and rewrite its archetype / card-name references to "GodMind".
	--(While "GodMind Processing Universe" is face-up on your field it adds a Quick Effect clone of this effect.)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_CONTROL+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(SET_GODMIND,lc,sumtype,tp)
end
--target: a face-up monster, or a face-up Continuous Spell/Trap, or a face-up Field Spell
function s.filter(c,tp)
	if not c:IsFaceup() then return false end
	if c:IsMonster() then return c:IsControlerCanBeChanged() end
	if c:IsType(TYPE_FIELD) then return true end
	return c:IsSpellTrap() and c:IsType(TYPE_CONTINUOUS) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and s.filter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,0,LOCATION_ONFIELD,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,s.filter,tp,0,LOCATION_ONFIELD,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
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
	--...then take control of it (monsters: change control; Spells/Traps: move to your Spell & Trap Zone / Field Zone)
	if tc:IsMonster() then
		Duel.GetControl(tc,tp)
	elseif tc:IsType(TYPE_FIELD) then
		local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
		if fc then
			Duel.SendtoGrave(fc,REASON_RULE)
			Duel.BreakEffect()
		end
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
	else
		if Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		end
	end
	if not tc:IsControler(tp) then return end
	--the negation ends once it is on your field
	e1:Reset()
	e2:Reset()
	--hijack it: treated as a "GodMind" card, archetype / card-name references rewritten to "GodMind"
	s.hijack(c,tc)
	--a monster becomes LIGHT and Machine, or LIGHT and Cyberse if it is an Extra Deck monster
	s.lightform(c,tc)
end
--The standard resets WITHOUT "moved to the field": hijack effects can be put on a monster while it is still in the Extra Deck
--and must survive it being Special Summoned (they still end when it leaves the field, goes to the hand, Deck, GY, etc.).
local RESET_HIJACK=RESET_EVENT|(RESETS_STANDARD&~RESET_TOFIELD)
--Hijack (also used by "Processing Universe", "GodMind SuIntelligence" and "GodMind Shi'arWare", which load this script with
--Duel.LoadCardScript): the card becomes a "GodMind" card and its archetype / card-name references are rewritten to "GodMind".
--c = the card that creates the effects, tc = the hijacked card.
--For a monster that is about to be Special Summoned from the Extra Deck, call this BEFORE the Summon: its "when Special Summoned"
--trigger is collected as soon as it is summoned, so the rewritten effects have to exist by then (calling it afterwards let the
--original, unrewritten trigger fire).
function s.hijack(c,tc)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ADD_SETCODE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(SET_GODMIND)
	e1:SetReset(RESET_HIJACK)
	tc:RegisterEffect(e1,true)
	--marker: "this card is treated as GodMind by a hijack" (used by "GodMind Processor 10² StarWare"'s Pendulum Effect: tc:HasFlagEffect(99900011))
	tc:RegisterFlagEffect(id,RESET_HIJACK,0,1)
	s.rewrite(tc)
end
--A monster becomes LIGHT and Machine, or LIGHT and Cyberse if it is an Extra Deck monster
--(also used by "GodMind SuIntelligence"). Does nothing for Spells / Traps.
function s.lightform(c,tc)
	if not tc:IsMonster() then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(ATTRIBUTE_LIGHT)
	e1:SetReset(RESET_HIJACK)
	tc:RegisterEffect(e1,true)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_RACE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	if tc:IsType(TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK) then
		e2:SetValue(RACE_CYBERSE)
	else
		e2:SetValue(RACE_MACHINE)
	end
	e2:SetReset(RESET_HIJACK)
	tc:RegisterEffect(e2,true)
end
--Rewrite.
--For the stolen card, every check it makes against an archetype or a card name now asks "is this a GodMind card?":
--  c:IsSetCard(anything)
--  c:IsCode(x), c:ListsCode(x)   for every code x except the stolen card's own code
--  c:IsAttribute(anything)       -> is c LIGHT?
--  c:IsRace(anything)            -> is c a Machine or Cyberse monster?
--This is applied two ways:
--  1) the functions of its effects (condition / cost / target / operation / value) are wrapped, so checks made while they run are remapped;
--  2) its setup (initial_effect) is run again while the remap is active, so filters it built in advance, like
--     aux.FaceupFilter(Card.IsCode,x), capture the remapped check instead of the original one.
--     The old effects are removed once the new ones are registered. (Side effect: its once-per-turn counters start fresh.)
--Restrictions.
--Restrictions that are part of the hijacked card (its own continuous effects) stay as they are.
--A restriction it registers while one of its effects resolves (a "cannot Summon / Set / activate / attack / send ..." field effect
--registered with Duel.RegisterEffect / Card.RegisterEffect) is replaced by a single one instead:
--you can only activate "GodMind" cards or effects. It keeps the original's condition, range and reset.
local RESTRICTION_CODES={}
for _,name in ipairs({"EFFECT_CANNOT_SUMMON","EFFECT_CANNOT_MSET","EFFECT_CANNOT_SSET","EFFECT_CANNOT_SPECIAL_SUMMON","EFFECT_CANNOT_FLIP_SUMMON",
	"EFFECT_CANNOT_ACTIVATE","EFFECT_CANNOT_TRIGGER","EFFECT_CANNOT_ATTACK","EFFECT_CANNOT_ATTACK_ANNOUNCE","EFFECT_CANNOT_DIRECT_ATTACK",
	"EFFECT_CANNOT_SELECT_BATTLE_TARGET","EFFECT_CANNOT_BP","EFFECT_CANNOT_CHANGE_POSITION","EFFECT_CANNOT_TO_HAND","EFFECT_CANNOT_TO_DECK",
	"EFFECT_CANNOT_TO_GRAVE","EFFECT_CANNOT_REMOVE","EFFECT_CANNOT_DISCARD_HAND","EFFECT_CANNOT_DISCARD_DECK","EFFECT_CANNOT_DRAW"}) do
	local v=_G[name]
	if v then RESTRICTION_CODES[v]=true end
end
--also every other "cannot ..." / "skip ..." code (except protections the card gives: "cannot be targeted / destroyed / negated ...")
for name,v in pairs(_G) do
	if type(name)=="string" and type(v)=="number" and (name:find("^EFFECT_CANNOT_") or name:find("^EFFECT_SKIP_"))
		and not (name:find("_BE_") or name:find("DISABLE") or name:find("INACTIVATE") or name:find("DISEFFECT") or name:find("NEGATE")) then
		RESTRICTION_CODES[v]=true
	end
end
local REPLACED_LABEL=99900011
function s.isrestriction(e)
	return e:IsHasType(EFFECT_TYPE_FIELD) and RESTRICTION_CODES[e:GetCode()] and e:GetLabel()~=REPLACED_LABEL
end
--an effect that only shows a hint to a player (what aux.RegisterClientHint registers)
function s.ishint(e)
	local p1=e:GetProperty()
	return e:GetLabel()~=REPLACED_LABEL and e:GetCode()==0 and (p1&EFFECT_FLAG_CLIENT_HINT)~=0 and (p1&EFFECT_FLAG_PLAYER_TARGET)~=0
end
function s.actlimit(e,re,tp)
	return not s.rawsetcard(re:GetHandler(),SET_GODMIND)
end
--the replacement of restriction effect "te" (p = the player it applies to, "you")
function s.replacement(te,p)
	local e1=Effect.CreateEffect(te:GetOwner())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	--client hint: shows what the restriction now actually is ("Cannot activate cards or effects except "GodMind" cards or effects")
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET|EFFECT_FLAG_SET_AVAILABLE|EFFECT_FLAG_IGNORE_IMMUNE|EFFECT_FLAG_CLIENT_HINT)
	e1:SetTargetRange(1,0)
	e1:SetLabel(REPLACED_LABEL)
	e1:SetValue(s.actlimit)
	--only gets a range if the original had one (a global effect must not depend on the card staying on the field)
	local r=te:GetRange()
	if r~=0 then e1:SetRange(r) end
	local cond=te:GetCondition()
	if cond then e1:SetCondition(cond) end
	local rst,rct=te:GetReset()
	if rst and rst~=0 then e1:SetReset(rst,rct) end
	return e1
end
--A restriction is only replaced if it applies to the card's controller ("you"). One aimed only at the opponent is kept as it is.
--One aimed at both sides keeps its opponent half (a copy with the target range (0,o)) and only its own half is replaced.
--Returns whether it applies to the controller, and the opponent-only copy (or nil).
function s.splitrestriction(e)
	local sr,orr=e:GetTargetRange()
	if not sr or sr==0 then return false,nil end
	local opp=nil
	if orr and orr~=0 then
		opp=e:Clone()
		opp:SetTargetRange(0,orr)
	end
	return true,opp
end
local o_IsSetCard=Card.IsSetCard
local o_IsCode=Card.IsCode
local o_ListsCode=Card.ListsCode
local o_IsAttribute=Card.IsAttribute
local o_IsRace=Card.IsRace
local o_DuelRegisterEffect=Duel.RegisterEffect
local o_CardRegisterEffect=Card.RegisterEffect
s.rawsetcard=o_IsSetCard
local cur=nil --patch currently installed (nil = the real functions)
local function makepatch(own,tc)
	local P={own=own}
	function P.IsSetCard(c,...)
		return o_IsSetCard(c,SET_GODMIND)
	end
	--any Attribute it mentions becomes LIGHT, any monster Type it mentions becomes Machine / Cyberse
	function P.IsAttribute(c,...)
		return o_IsAttribute(c,ATTRIBUTE_LIGHT)
	end
	function P.IsRace(c,...)
		return o_IsRace(c,RACE_MACHINE|RACE_CYBERSE)
	end
	function P.IsCode(c,...)
		for i=1,select('#',...) do
			local x=select(i,...)
			if x~=own then
				dbglimited("remapped IsCode("..tostring(x)..") on card "..tostring(c:GetOriginalCode())..": GodMind="..tostring(o_IsSetCard(c,SET_GODMIND)))
				if o_IsSetCard(c,SET_GODMIND) then return true end
			elseif o_IsCode(c,x) then
				return true
			end
		end
		return false
	end
	function P.ListsCode(c,...)
		for i=1,select('#',...) do
			local x=select(i,...)
			if x~=own then
				if o_IsSetCard(c,SET_GODMIND) then return true end
			elseif o_ListsCode(c,x) then
				return true
			end
		end
		return false
	end
	--a restriction this card registers while one of its effects is running (P.active, set by s.wrap) becomes
	--"you can only activate GodMind cards or effects". Restrictions that are part of the card are left alone.
	function P.DuelRegisterEffect(e,p)
		if P.active and e:GetOwner()==tc then
			if s.isrestriction(e) then
				local mine,opp=s.splitrestriction(e)
				if mine then
					if opp then o_DuelRegisterEffect(opp,p) end
					e=s.replacement(e,p)
					P.replaced=true
				end
			elseif s.ishint(e) then
				--a hint-only effect ("You cannot ... this turn" icon): held back until the effect finishes running,
				--and dropped if a restriction was replaced meanwhile (the new hint takes its place)
				table.insert(P.pending,{e=e,p=p})
				return
			end
		end
		return o_DuelRegisterEffect(e,p)
	end
	function P.CardRegisterEffect(c,e,...)
		if P.active and s.isrestriction(e) and e:GetOwner()==tc then
			local mine,opp=s.splitrestriction(e)
			if mine then
				if opp then o_CardRegisterEffect(c,opp,...) end
				e=s.replacement(e,tc:GetControler())
				P.replaced=true
			end
		end
		local r=o_CardRegisterEffect(c,e,...)
		--while the setup is re-run (P.recording), remember every effect it registers on the card: they are wrapped directly,
		--without asking Card.GetCardEffect for them (it only lists effects that are available RIGHT NOW)
		if P.recording and c==tc then table.insert(P.created,e) end
		return r
	end
	return P
end
local function install(P)
	cur=P
	Card.IsSetCard=P and P.IsSetCard or o_IsSetCard
	Card.IsCode=P and P.IsCode or o_IsCode
	Card.ListsCode=P and P.ListsCode or o_ListsCode
	Card.IsAttribute=P and P.IsAttribute or o_IsAttribute
	Card.IsRace=P and P.IsRace or o_IsRace
	Duel.RegisterEffect=P and P.DuelRegisterEffect or o_DuelRegisterEffect
	Card.RegisterEffect=P and P.CardRegisterEffect or o_CardRegisterEffect
end
function s.wrap(f,P)
	return function(...)
		dbglimited("wrapped effect function called (patch for "..tostring(P.own)..")")
		local prev=cur
		install(P)
		--restrictions registered while the effect runs get replaced (see P.RegisterEffect)
		local wasactive=P.active
		if not wasactive then
			P.pending={}
			P.replaced=false
		end
		P.active=true
		local r=table.pack(pcall(f,...))
		P.active=wasactive
		if not wasactive then
			--hint-only effects that were held back are only registered if no restriction was replaced
			local pending,replaced=P.pending,P.replaced
			P.pending,P.replaced=nil,false
			if not replaced then
				for _,h in ipairs(pending) do o_DuelRegisterEffect(h.e,h.p) end
			end
		end
		install(prev)
		if not r[1] then error(r[2],0) end
		return table.unpack(r,2,r.n)
	end
end
function s.wrapeffects(P,list)
	for _,te in ipairs(list) do
		dbg("wrapping effect: "..describe(te))
		wrappedeffects[te]=true
		local f=te:GetCondition()
		if f then te:SetCondition(s.wrap(f,P)) end
		f=te:GetCost()
		if f then te:SetCost(s.wrap(f,P)) end
		f=te:GetTarget()
		if f then te:SetTarget(s.wrap(f,P)) end
		f=te:GetOperation()
		if f then te:SetOperation(s.wrap(f,P)) end
		f=te:GetValue()
		if type(f)=="function" then te:SetValue(s.wrap(f,P)) end
	end
end
function s.ownlist(tc)
	local list={}
	--only the card's own effects, not the ones other cards (like the negation / "GodMind" setcode above) put on it
	for _,te in ipairs{tc:GetCardEffect()} do
		if te:GetOwner()==tc then table.insert(list,te) end
	end
	return list
end
--Card.GetCardEffect only lists the effects that are AVAILABLE right now (a monster-zone effect of a card still in the Extra Deck / GY,
--a Spell & Trap Zone effect of a Set card, an effect whose condition is false are NOT listed). error.log of 2026-11-23 confirmed it:
--Altergeist Hexstia, hijacked from the Extra Deck, had 7 effects before and 4 after the re-run, and its ATK effect and its Quick Effect
--were never wrapped. Two fixes:
--  1) the effects the re-run setup creates are collected while it runs (P.created) and wrapped directly (no listing needed);
--  2) the ORIGINAL effects that were not listed are removed later, as soon as they do show up in the list (s.latefix, from a watcher on
--     EVENT_ADJUST). An effect is "original" if it was registered before the hijack started: effect IDs grow with time, so it is older
--     than hijackstamp.
local hijackstamp=setmetatable({},{__mode="k"}) --card -> effect ID counter at the start of its last hijack
function s.latefix(tc)
	local stamp=hijackstamp[tc]
	if not stamp then return end
	for _,te in ipairs{tc:GetCardEffect()} do
		if te:GetOwner()==tc and te:GetFieldID()<stamp then
			dbg("latefix: resetting original effect of "..tc:GetOriginalCode()..": "..describe(te))
			te:Reset()
		end
	end
end
function s.watch(tc)
	local ew=Effect.CreateEffect(tc)
	ew:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ew:SetCode(EVENT_ADJUST)
	ew:SetOperation(function(e)
		if not tc:HasFlagEffect(id) then
			--the hijack is over (the card left the field, ...)
			hijackstamp[tc]=nil
			e:Reset()
			return
		end
		s.latefix(tc)
	end)
	o_DuelRegisterEffect(ew,0)
end
function s.rewrite(tc)
	local P=makepatch(tc:GetOriginalCode(),tc)
	P.created={}
	--remember how far the effect IDs have come, to tell the card's original effects from the ones registered from now on
	local stampfx=Effect.CreateEffect(tc)
	stampfx:SetType(EFFECT_TYPE_SINGLE)
	stampfx:SetCode(99900303)
	o_CardRegisterEffect(tc,stampfx,true)
	hijackstamp[tc]=stampfx:GetFieldID()
	stampfx:Reset()
	local old=s.ownlist(tc)
	local mt=Duel.GetMetatable(tc:GetOriginalCode())
	local rebuilt=false
	dbg("rewrite of "..tc:GetOriginalCode().." (location "..tc:GetLocation().."): "..#old.." own effects found, metatable="..tostring(mt~=nil)
		..", initial_effect="..tostring(mt~=nil and mt.initial_effect~=nil))
	if mt and mt.initial_effect then
		--run its setup again with the remap active
		local prev=cur
		install(P)
		P.recording=true
		local ok,err=pcall(mt.initial_effect,tc)
		P.recording=false
		install(prev)
		dbg("setup re-run ok="..tostring(ok)..(ok and "" or (", ERROR: "..tostring(err))))
		if ok then
			rebuilt=true
			for _,te in ipairs(old) do te:Reset() end
		end
	end
	dbg("after re-run: "..#P.created.." effects created (rebuilt="..tostring(rebuilt)..")")
	if rebuilt then
		s.wrapeffects(P,P.created)
	else
		--fallback: just wrap the existing effects
		s.wrapeffects(P,old)
	end
	s.watch(tc)
	dbg("rewrite done; is GodMind now: "..tostring(o_IsSetCard(tc,SET_GODMIND)))
end
