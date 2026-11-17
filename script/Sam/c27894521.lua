--Star Seraph Scythe
local s,id=GetID()
--marker code that points at an Xyz Monster's effects that detach material as cost
--(created by RegisterEffect(e,false,REGISTER_FLAG_DETACH_XMAT))
local DETACH_MARKER=511002571
--per Xyz Monster: the effects that already got a Quick Effect version
s.converted={}
--effects whose Ignition version was already blocked while the Quick Effect version exists
s.wrapped={}
function s.initial_effect(c)
	--If you control a "Star Seraph" monster: You can Special Summon this card from your hand or GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND|LOCATION_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--A "Star Seraph" Xyz Monster with this card as material gains the following effect:
	--If it is Xyz Summoned: While this card is on the field, you activate this card's effects that detach material as Quick Effects
	--(same setup as "Star Seraph Scepter": when this card becomes Xyz material, the effect is given to the Xyz Monster)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.effcon)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_STAR_SERAPH}
--Special Summon
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_STAR_SERAPH)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end
--Effect gain
function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetHandler():GetReasonCard()
	return r==REASON_XYZ and rc and rc:IsSetCard(SET_STAR_SERAPH)
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetHandler():GetReasonCard()
	--If it is Xyz Summoned: ...
	local e1=Effect.CreateEffect(rc)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.qcon)
	e1:SetOperation(s.qop)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e1,true)
end
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.qop(e,tp,eg,ep,ev,re,r,rp)
	local xc=e:GetHandler()
	if not (xc:IsFaceup() and xc:IsLocation(LOCATION_MZONE)) then return end
	s.converted[xc]={}
	--...while this card is on the field
	if xc:GetFlagEffect(id)==0 then
		xc:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,1))
		--keep checking (adjust), so effects this card gains later are covered too
		local e1=Effect.CreateEffect(xc)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_ADJUST)
		e1:SetRange(LOCATION_MZONE)
		e1:SetOperation(s.adjop)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		xc:RegisterEffect(e1,true)
	end
	s.convert(xc)
end
function s.adjop(e,tp,eg,ep,ev,re,r,rp)
	s.convert(e:GetHandler())
end
--an effect "that detaches material": registered with the detach marker, or an Ignition Effect of this
--Xyz Monster on the field that has a cost (e.g. Cost.Detach, or a cost that calls RemoveOverlayCard)
function s.isdetacheffect(xc,te,marked)
	if not te:IsHasType(EFFECT_TYPE_IGNITION) then return false end
	if (te:GetRange()&LOCATION_MZONE)==0 then return false end
	return marked[te] or (te:GetCost()~=nil and te:GetOwner()==xc)
end
function s.convert(xc)
	if xc:GetFlagEffect(id)==0 then return end
	local done=s.converted[xc]
	if not done then
		done={}
		s.converted[xc]=done
	end
	local marked={}
	for _,marker in ipairs({xc:GetCardEffect(DETACH_MARKER)}) do
		local te=marker:GetLabelObject()
		if te then marked[te]=true end
	end
	for _,te in ipairs({xc:GetCardEffect()}) do
		if not done[te] and s.isdetacheffect(xc,te,marked) then
			done[te]=true
			s.makequick(xc,te)
		end
	end
end
function s.makequick(xc,te)
	local ocon,ocost,otg,oop=te:GetCondition(),te:GetCost(),te:GetTarget(),te:GetOperation()
	local _,max,code,flag,hopt=te:GetCountLimit()
	max=max or 0
	flag=flag or 0
	--hard once per turn ("You can only use this effect of ... once per turn"): share the same counter
	local shared=max>0 and code~=nil and code~=0
	--the Ignition version cannot be used while the Quick Effect version is available
	if not s.wrapped[te] then
		s.wrapped[te]=true
		te:SetCondition(function(e,...)
			if e:GetHandler():GetFlagEffect(id)>0 then return false end
			return not ocon or ocon(e,...)
		end)
	end
	local e1=Effect.CreateEffect(xc)
	if te:GetDescription() then e1:SetDescription(te:GetDescription()) end
	e1:SetCategory(te:GetCategory())
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	local p1,p2=te:GetProperty()
	e1:SetProperty(p1 or 0,p2 or 0)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	if shared then
		e1:SetCountLimit(max,{code,hopt or 0},flag)
	end
	e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		if c:GetFlagEffect(id)==0 then return false end
		if max>0 and not shared then
			--plain "Once per turn": shared with the Ignition version through a flag
			if c:GetFlagEffect(id+1)>=max then return false end
			local remain=te:GetCountLimit()
			if type(remain)=="number" and remain<=0 then return false end
		end
		return not ocon or ocon(e,tp,eg,ep,ev,re,r,rp)
	end)
	e1:SetCost(function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return not ocost or ocost(e,tp,eg,ep,ev,re,r,rp,0) end
		if ocost then ocost(e,tp,eg,ep,ev,re,r,rp,1) end
		if max>0 and not shared then
			e:GetHandler():RegisterFlagEffect(id+1,RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,0,1)
		end
	end)
	if otg then e1:SetTarget(otg) end
	if oop then e1:SetOperation(oop) end
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	xc:RegisterEffect(e1,true)
end
