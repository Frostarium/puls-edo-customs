--GodMind Processor 10² SuIntelligence   (upgraded Pendulum version of "GodMind SuIntelligence"; Lv8 Fusion Pendulum, Pendulum Scale 10)
--[ Pendulum Effect ] During your Main Phase: You can Special Summon 1 "GodMind" monster from your GY or banishment.
--  You can only use this effect of "GodMind Processor 10² SuIntelligence" once per turn.
--[ Monster Effect ] 1 "GodMind" monster + 1 "GodMind" Fusion Monster   (a real Level 8, so it Pendulum Summons with scales 2 and 10: no extra line needed)
--  Ignition: Special Summon 1 "Programmed Token" to your opponent's field in Defense Position            (= SuIntelligence's, shared code; Quick Effect via Processing Universe)
--  Ignition (NEW): target 1 monster YOUR OPPONENT controls; destroy it                                             (Quick Effect via Processing Universe)
--  If this card destroys an opponent's monster by battle, or an opponent's monster is destroyed by this card's effect:
--    the Extra Deck steal of "GodMind SuIntelligence" (shared code: base.sptg / base.spop, hijacked before the Summon). Hard once per turn (the two triggers share the code).
local s,id=GetID()
local SET_GODMIND=0x1650
local base=Duel.LoadCardScript(99900012)
s.listed_series={SET_GODMIND}
s.material_setcode=SET_GODMIND
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
	--1 "GodMind" monster + 1 "GodMind" Fusion Monster
	Fusion.AddProcMix(c,true,true,s.matfilter,s.fusfilter)
	--Pendulum Effect: Special Summon 1 "GodMind" monster from your GY or banishment
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,3))
	e0:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e0:SetType(EFFECT_TYPE_IGNITION)
	e0:SetRange(LOCATION_PZONE)
	e0:SetCountLimit(1,{id,3})
	e0:SetTarget(s.psptg)
	e0:SetOperation(s.pspop)
	c:RegisterEffect(e0)
	--When this card destroys an opponent's monster by battle: the Extra Deck steal
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_BATTLE_DESTROYING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(aux.bdocon)
	e1:SetTarget(base.sptg)
	e1:SetOperation(base.spop)
	c:RegisterEffect(e1)
	--...or when an opponent's monster is destroyed by this card's effect (same hard once per turn)
	local e1b=Effect.CreateEffect(c)
	e1b:SetDescription(aux.Stringid(id,0))
	e1b:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1b:SetProperty(EFFECT_FLAG_DELAY)
	e1b:SetCode(EVENT_DESTROYED)
	e1b:SetRange(LOCATION_MZONE)
	e1b:SetCountLimit(1,id)
	e1b:SetCondition(s.descon)
	e1b:SetTarget(base.sptg)
	e1b:SetOperation(base.spop)
	c:RegisterEffect(e1b)
	--Ignition: Special Summon 1 "Programmed Token" to your opponent's field in Defense Position
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOKEN+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(base.tktg)
	e2:SetOperation(base.tkop)
	c:RegisterEffect(e2)
	--Ignition: target 1 monster on the field; destroy it
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_GODMIND,fc,sumtype,tp)
end
function s.fusfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_GODMIND,fc,sumtype,tp) and c:IsType(TYPE_FUSION,fc,sumtype,tp)
end
--Pendulum Effect
function s.pspfilter(c,e,tp)
	return c:IsSetCard(SET_GODMIND) and c:IsMonster() and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.psptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.pspfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
end
function s.pspop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.pspfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
--an opponent's monster was destroyed by an effect of this card
function s.desfilter(c,tp,rc)
	if not (c:IsReason(REASON_EFFECT) and c:IsPreviousControler(1-tp) and c:IsPreviousLocation(LOCATION_MZONE)) then return false end
	local re=c:GetReasonEffect()
	return re~=nil and re:GetHandler()==rc
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.desfilter,1,nil,tp,e:GetHandler())
end
--Ignition: destroy 1 monster on the field
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	--only a monster your opponent controls
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

--Summoning condition: only by its own Summon procedure (FUSION Summon), a Pendulum Summon, its own effect, or "GodMind Computer Superprocess" (99900022)
function s.splimit(e,se,sp,st)
	if se then
		local sc=se:GetHandler()
		if sc==e:GetHandler() or sc:GetOriginalCode()==99900022 then return true end
	end
	return (st&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION or (st&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end
