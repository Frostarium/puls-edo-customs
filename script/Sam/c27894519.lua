--Number C102: Star Seraph Silence
local s,id=GetID()
local CARD_NUMBER_102_STAR_SERAPH_SENTRY=49678559
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon: 4 Level 4 LIGHT Fairy monsters
	--Once per turn, you can also Xyz Summon this card using 1 "Number 102: Star Seraph Sentry" you control
	Xyz.AddProcedure(c,s.mfilter,4,4,s.ovfilter,aux.Stringid(id,0),4,s.xyzop)
	--Detach 1 material; destroy 1 card your opponent controls, then if it was a monster, gain LP
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1,false,REGISTER_FLAG_DETACH_XMAT)
	--If this card would be destroyed, you can detach 1 material from this card instead
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.reptg)
	c:RegisterEffect(e2)
end
s.xyz_number=102
s.listed_names={CARD_NUMBER_102_STAR_SERAPH_SENTRY}
s.listed_series={SET_STAR_SERAPH}
function s.mfilter(c,xyz,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT,xyz,sumtype,tp) and c:IsRace(RACE_FAIRY,xyz,sumtype,tp)
end
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsSummonCode(xyzc,SUMMON_TYPE_XYZ,tp,CARD_NUMBER_102_STAR_SERAPH_SENTRY)
end
function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,EFFECT_FLAG_OATH,1)
	return true
end
--Destroy + gain LP
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	Duel.HintSelection(g,true)
	local ismonster=tc:IsMonster()
	--the ATK it had while on the field
	local fieldatk=ismonster and math.max(tc:GetAttack(),0) or 0
	if Duel.Destroy(tc,REASON_EFFECT)>0 and ismonster then
		--its original ATK (in the GY)
		local origatk=math.max(tc:GetTextAttack(),0)
		local lp=math.abs(fieldatk-origatk)
		if lp>0 then
			Duel.BreakEffect()
			Duel.Recover(tp,lp,REASON_EFFECT)
		end
	end
end
--Destruction replacement
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsReason(REASON_REPLACE) and c:IsReason(REASON_BATTLE|REASON_EFFECT)
		and c:CheckRemoveOverlayCard(tp,1,REASON_EFFECT) end
	if Duel.SelectEffectYesNo(tp,c,96) then
		c:RemoveOverlayCard(tp,1,1,REASON_EFFECT)
		return true
	end
	return false
end
