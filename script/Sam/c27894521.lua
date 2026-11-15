--Star Seraph Scythe
local s,id=GetID()
--marker code that gives access to an Xyz Monster's effects that detach material as cost
--(set by RegisterEffect(e,false,REGISTER_FLAG_DETACH_XMAT))
local DETACH_MARKER=511002571
--Xyz Monsters that already have their detaching effects converted, and the effects that were already handled
s.converted={}
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
	--If it is Xyz Summoned: While this card is on the field, you activate this card's effect that detaches material as a Quick Effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.qcon)
	e2:SetOperation(s.qop)
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
--Gained effect (e:GetHandler() is the Xyz Monster that has this card as material)
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
	local xc=e:GetHandler()
	return xc:IsSetCard(SET_STAR_SERAPH) and xc:IsSummonType(SUMMON_TYPE_XYZ)
end
function s.qop(e,tp,eg,ep,ev,re,r,rp)
	local xc=e:GetHandler()
	if not xc:IsFaceup() or not xc:IsLocation(LOCATION_MZONE) then return end
	Duel.Hint(HINT_CARD,0,id)
	s.converted[xc]={}
	--while this card is on the field
	if xc:GetFlagEffect(id)==0 then
		xc:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,1))
		--adjust: give every effect of this card that detaches material a Quick Effect version
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
function s.convert(xc)
	if xc:GetFlagEffect(id)==0 then return end
	local done=s.converted[xc]
	if not done then
		done={}
		s.converted[xc]=done
	end
	local effs={xc:GetCardEffect(DETACH_MARKER)}
	for _,marker in ipairs(effs) do
		local te=marker:GetLabelObject()
		if te and not done[te] and te:IsHasType(EFFECT_TYPE_IGNITION) then
			done[te]=true
			s.makequick(xc,te)
		end
	end
end
function s.makequick(xc,te)
	local ocon,ocost,otg,oop=te:GetCondition(),te:GetCost(),te:GetTarget(),te:GetOperation()
	local rm,max,code,flag,hopt=te:GetCountLimit()
	local shared=(flag&EFFECT_COUNT_CODE_SINGLE==0) and code and code~=0
	--the original (Ignition) version is not usable while the Quick Effect version is available
	if not s.wrapped[te] then
		s.wrapped[te]=true
		te:SetCondition(function(e,...)
			if e:GetHandler():GetFlagEffect(id)>0 then return false end
			return not ocon or ocon(e,...)
		end)
	end
	local e1=Effect.CreateEffect(xc)
	e1:SetDescription(te:GetDescription())
	e1:SetCategory(te:GetCategory())
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(te:GetRange())
	local p1,p2=te:GetProperty()
	e1:SetProperty(p1,p2)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetLabel(te:GetLabel())
	e1:SetLabelObject(te:GetLabelObject())
	if shared then
		--same once-per-turn counter as the original effect
		e1:SetCountLimit(max,{code,hopt},flag)
	end
	e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
		if e:GetHandler():GetFlagEffect(id)==0 then return false end
		if not shared then
			--"once per turn" tied to the original effect: it must not have been used yet, nor this copy
			local remain=te:GetCountLimit()
			if remain and remain<=0 then return false end
			if e:GetHandler():GetFlagEffect(id+1)>0 then return false end
		end
		return not ocon or ocon(e,tp,eg,ep,ev,re,r,rp)
	end)
	e1:SetCost(function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return not ocost or ocost(e,tp,eg,ep,ev,re,r,rp,chk) end
		if ocost then ocost(e,tp,eg,ep,ev,re,r,rp,chk) end
		if not shared then
			e:GetHandler():RegisterFlagEffect(id+1,RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,0,1)
		end
	end)
	if otg then e1:SetTarget(otg) end
	if oop then e1:SetOperation(oop) end
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	xc:RegisterEffect(e1,true)
end
