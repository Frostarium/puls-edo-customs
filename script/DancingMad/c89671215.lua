--Poltrgeist of the Warring Triad
local s,id,o=GetID()
local COUNTER_STOP=0x1633
local CARD_TYRFING=89671217
s.listed_names={CARD_TYRFING}
function s.initial_effect(c)
	--Synchro Summon procedure: 1 Level 3 EARTH Wyrm Tuner + 1 Level 3 EARTH Wyrm non-Tuner
	Synchro.AddProcedure(c,s.matfilter,1,1,Synchro.NonTunerEx2(s.matfilter),1,1)
	--Place a Stop Counter on 1 monster your opponent controls
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCost(s.ctcost)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)
	--Monsters with a Stop Counter cannot be used as material for a Fusion, Synchro, Xyz or Link Summon
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetTarget(s.stoptg)
	e2:SetValue(aux.cannotmatfilter(SUMMON_TYPE_FUSION,SUMMON_TYPE_SYNCHRO,SUMMON_TYPE_XYZ,SUMMON_TYPE_LINK))
	c:RegisterEffect(e2)
	--...and cannot be Tributed (for a Tribute Summon, or by a card effect or as a cost)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UNRELEASABLE_SUM)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	e4:SetValue(1)
	c:RegisterEffect(e4)
	--Their controller must discard a card to activate the effects of a monster with a Stop Counter
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_ACTIVATE_COST)
	e5:SetRange(LOCATION_MZONE)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetTargetRange(0,1)
	e5:SetTarget(s.actarget)
	e5:SetCost(s.costchk)
	e5:SetOperation(s.costop)
	c:RegisterEffect(e5)
	--During the End Phase, destroy all monsters with a Stop Counter
	local e6=Effect.CreateEffect(c)
	e6:SetCategory(CATEGORY_DESTROY)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e6:SetCode(EVENT_PHASE+PHASE_END)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetCondition(s.gycon)
	e6:SetTarget(s.gytg)
	e6:SetOperation(s.gyop)
	c:RegisterEffect(e6)
end
s.counter_place_list={COUNTER_STOP}
--once per turn, or twice per turn while "Tyrfing" is equipped to this card (shared by all copies, like a hard once per turn)
function s.ctcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local max=c:GetEquipGroup():IsExists(Card.IsOriginalCode,1,nil,CARD_TYRFING) and 2 or 1
	if chk==0 then return Duel.GetFlagEffect(tp,id)<max end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
end
function s.matfilter(c,scard,sumtype,tp)
	return c:IsLevel(3) and c:IsAttribute(ATTRIBUTE_EARTH,scard,sumtype,tp) and c:IsRace(RACE_WYRM,scard,sumtype,tp)
end
function s.stoptg(e,c)
	return c:IsFaceup() and c:GetCounter(COUNTER_STOP)>0
end
function s.ctfilter(c)
	return c:IsFaceup() and c:IsCanAddCounter(COUNTER_STOP,1)
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.ctfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.ctfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
	local g=Duel.SelectTarget(tp,s.ctfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,g,1,COUNTER_STOP,1)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		tc:AddCounter(COUNTER_STOP,1)
	end
end
--the effect being activated is that of a monster with a Stop Counter
function s.actarget(e,te,tp)
	local tc=te:GetHandler()
	return te:IsMonsterEffect() and tc:IsOnField() and tc:GetCounter(COUNTER_STOP)>0
end
function s.costchk(e,te,tp)
	return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,te:GetHandler())
end
function s.costop(e,tp,eg,ep,ev,re,r,rp)
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST|REASON_DISCARD)
end
function s.stopfilter(c)
	return c:GetCounter(COUNTER_STOP)>0
end
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.stopfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(s.stopfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.stopfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
