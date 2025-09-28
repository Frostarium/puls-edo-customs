--Darius
local s,id=GetID()
function s.initial_effect(c)
	--Global check for destroyed cards
	aux.GlobalCheck(s,function()
		local e0=Effect.CreateEffect(c)
		e0:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e0:SetCode(EVENT_DESTROYED)
		e0:SetOperation(s.acop)
		Duel.RegisterEffect(e0,0)
	end)
	
	--Special summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--Quick effect: destroy own card and opponent's card + adjacent zones
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	
	--Special summon 0x1735 monster when destroyed
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
end

--Global check functions
function s.acop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(Card.IsPreviousLocation,nil,LOCATION_ONFIELD)
	if ct>0 then
		Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,ct)
	end
end

--Special summon condition
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(0,id)>=3
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--Quick effect functions
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsDestructable,tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.IsExistingMatchingCard(Card.IsDestructable,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,Card.IsDestructable,tp,LOCATION_ONFIELD,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectTarget(tp,Card.IsDestructable,tp,0,LOCATION_ONFIELD,1,1,nil)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,2,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	if #g==2 then
		local tc1=g:GetFirst()
		local tc2=g:GetNext()
		local mycard,oppcard
		if tc1:IsControler(tp) then
			mycard=tc1
			oppcard=tc2
		else
			mycard=tc2
			oppcard=tc1
		end
		if Duel.Destroy(mycard,REASON_EFFECT)>0 then
			local seq=oppcard:GetSequence()
			local dg=Group.FromCards(oppcard)
			if oppcard:IsLocation(LOCATION_MZONE) then
				if seq>0 then
					local lc=Duel.GetFieldCard(1-tp,LOCATION_MZONE,seq-1)
					if lc then dg:AddCard(lc) end
					local lsc=Duel.GetFieldCard(1-tp,LOCATION_SZONE,seq-1)
					if lsc then dg:AddCard(lsc) end
				end
				if seq<4 then
					local rc=Duel.GetFieldCard(1-tp,LOCATION_MZONE,seq+1)
					if rc then dg:AddCard(rc) end
					local rsc=Duel.GetFieldCard(1-tp,LOCATION_SZONE,seq+1)
					if rsc then dg:AddCard(rsc) end
				end
			elseif oppcard:IsLocation(LOCATION_SZONE) and seq<5 then
				if seq>0 then
					local lc=Duel.GetFieldCard(1-tp,LOCATION_MZONE,seq-1)
					if lc then dg:AddCard(lc) end
					local lsc=Duel.GetFieldCard(1-tp,LOCATION_SZONE,seq-1)
					if lsc then dg:AddCard(lsc) end
				end
				if seq<4 then
					local rc=Duel.GetFieldCard(1-tp,LOCATION_MZONE,seq+1)
					if rc then dg:AddCard(rc) end
					local rsc=Duel.GetFieldCard(1-tp,LOCATION_SZONE,seq+1)
					if rsc then dg:AddCard(rsc) end
				end
			end
			Duel.Destroy(dg,REASON_EFFECT)
		end
	end
end

--Special summon 0x1735 monster functions
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x1735) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
