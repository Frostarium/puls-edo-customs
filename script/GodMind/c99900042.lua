--GodMind Processor 10² Technarch   (upgraded Pendulum version of "GodMind Technarch"; Rank 5 Xyz Pendulum, Pendulum Scale 2)
--[ Pendulum Effect ] During your Main Phase: You can Special Summon this card, then you can attach 1 monster from your GY or banishment to this card as material.
--  You can only use this effect of "GodMind Processor 10² Technarch" once per turn.
--[ Monster Effect ] 2 Level 5 "GodMind" monsters
--  If you can Pendulum Summon Level 5, you can Pendulum Summon this face-up card in your Extra Deck.
--  You can also Xyz Summon this card by discarding 1 "GodMind" monster and using "GodMind Technarch" you control as the Xyz Material (like Number 99: Utopic Dragon).
--  Ignition (Quick Effect via "GodMind Processing Universe"): target up to 2 face-up monsters YOUR OPPONENT controls (never your own monsters or this card); apply the "Forbidden Crown" effects of "GodMind Technarch" to them until the end of this turn (NO detach cost).
--  During the End Phase: attach the monsters you applied those effects to this turn to this card as material.
--  Ignition: Special Summon 1 monster your opponent owns that is attached to this card as material; it is hijacked (+ LIGHT/Machine) BEFORE it is Summoned.
--  Each effect once per turn.
local s,id=GetID()
local SET_GODMIND=0x1650
local CODE_TECHNARCH=99900013
local technarch=Duel.LoadCardScript(CODE_TECHNARCH)
local starware=Duel.LoadCardScript(99900011)
--Extra Deck Pendulum Monsters have no Level for the Pendulum Summon: proc_pendulum.lua reads this field
s.pendulum_level=5
function s.initial_effect(c)
	c:EnableReviveLimit()
	--must first be properly Summoned (or Pendulum Summoned, or Special Summoned by its own effect), or Special Summoned by "GodMind Computer Superprocess"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	Pendulum.AddProcedure(c,false)
	--2 Level 5 "GodMind" monsters, or discard 1 "GodMind" monster and use "GodMind Technarch" you control
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_GODMIND),5,2,s.ovfilter,aux.Stringid(id,0),2,s.xyzop)
	--Pendulum Effect: Special Summon this card, then you can attach 1 monster from your GY or banishment to it
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,1))
	e0:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e0:SetType(EFFECT_TYPE_IGNITION)
	e0:SetRange(LOCATION_PZONE)
	e0:SetCountLimit(1,id)
	e0:SetTarget(s.pensptg)
	e0:SetOperation(s.penspop)
	c:RegisterEffect(e0)
	--Ignition: apply "Forbidden Crown" to up to 2 face-up monsters (no cost)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--End Phase: attach the monsters affected this turn (same code as "GodMind Technarch")
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,3))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(technarch.atcon)
	e2:SetTarget(technarch.attg)
	e2:SetOperation(technarch.atop)
	c:RegisterEffect(e2)
	--Ignition: Special Summon 1 attached monster that your opponent owns, hijacked
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,4))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,3})
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end
--alternative Xyz Summon: discard 1 "GodMind" monster, use "GodMind Technarch" you control (Xyz Materials attached to it move over)
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsSummonCode(lc,SUMMON_TYPE_XYZ,tp,CODE_TECHNARCH)
end
function s.cfilter(c)
	return c:IsSetCard(SET_GODMIND) and c:IsMonster() and c:IsDiscardable()
end
function s.xyzop(e,tp,chk,mc)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local tc=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_HAND,0,nil):SelectUnselect(Group.CreateGroup(),tp,false,Xyz.ProcCancellable)
	if tc then
		Duel.SendtoGrave(tc,REASON_DISCARD|REASON_COST)
		return true
	else return false end
end
--Pendulum Effect
function s.pensptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.ovfilter2(c,xc,tp)
	return c:IsMonster() and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsCanBeXyzMaterial(xc,tp,REASON_EFFECT)
end
function s.penspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.ovfilter2),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,nil,c,tp)
	if #g==0 or not Duel.SelectYesNo(tp,aux.Stringid(id,5)) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTACH)
	local og=g:Select(tp,1,1,nil)
	if #og>0 then
		Duel.BreakEffect()
		Duel.Overlay(c,og)
	end
end
--Ignition: up to 2 monsters, same effects as "GodMind Technarch"
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	--only monsters your opponent controls (never your own monsters or this card)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and technarch.afilter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(technarch.afilter,tp,0,LOCATION_MZONE,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	local g=Duel.SelectTarget(tp,technarch.afilter,tp,0,LOCATION_MZONE,1,2,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tg=Duel.GetTargetCards(e):Filter(Card.IsFaceup,nil)
	for sc in tg:Iter() do
		technarch.apply(c,sc)
	end
end
--Ignition: Special Summon 1 attached monster that your opponent owns, treated as GodMind (hijack BEFORE the Summon, like the Extra Deck summons do)
--The monster is hijacked FIRST and only then checked for being Summonable: hijacking rewrites the monster's own Summoning conditions too
--(a condition like "can only be Special Summoned by an X card's effect" becomes "by a GodMind card's effect"), so a check made before the hijack
--would wrongly reject monsters that this card can Summon. That is why the candidates are not filtered by IsCanBeSpecialSummoned.
function s.spfilter(c,tp)
	return c:IsMonster() and c:GetOwner()==1-tp
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:GetOverlayGroup():IsExists(s.spfilter,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_OVERLAY)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local g=c:GetOverlayGroup():Filter(s.spfilter,nil,tp)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	--hijack it while it is still attached (before it hits the field), LIGHT + Machine / Cyberse...
	starware.hijack(c,tc)
	starware.lightform(c,tc)
	--...and only now check that it can be Special Summoned (with its rewritten Summoning conditions) and Summon it
	if tc:IsCanBeSpecialSummoned(e,0,tp,false,false) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

--Summoning condition: only by its own Summon procedure (XYZ Summon), a Pendulum Summon, its own effect, or "GodMind Computer Superprocess" (99900022)
function s.splimit(e,se,sp,st)
	if se then
		local sc=se:GetHandler()
		if sc==e:GetHandler() or sc:GetOriginalCode()==99900022 then return true end
	end
	return (st&SUMMON_TYPE_XYZ)==SUMMON_TYPE_XYZ or (st&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end
