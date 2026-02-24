--Core Protector Alicorn
local s,id=GetID()
function s.initial_effect(c)
	--Can only control 1
	c:SetUniqueOnField(1,0,id)
	
	--Special Summon proc
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	
	--ATK/DEF boost
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.atktg)
	e2:SetCondition(s.atkcon)
	e2:SetValue(1000)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)
	
	--Quick effect tribute
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCost(s.trcost)
	e4:SetTarget(s.trtg)
	e4:SetOperation(s.trop)
	c:RegisterEffect(e4)
end
s.listed_names={7458100}

function s.corefilter(c)
	return c:IsFaceup() and c:IsCode(7458100) --Reality Core ID
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.corefilter,tp,LOCATION_ONFIELD,0,1,nil)
end

function s.atkcon(e)
	return Duel.IsExistingMatchingCard(s.corefilter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end

function s.atktg(e,c)
	return c:ListsCode(7458100)
end

function s.trcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end

function s.setfilter(c)
	return c:IsCode(7458100) and c:IsSpellTrap() and c:IsSSetable()
end

function s.protfilter(c)
	return c:IsFaceup() and c:ListsCode(7458100)
end

function s.trtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.protfilter,tp,LOCATION_MZONE,0,1,e:GetHandler())
	if chk==0 then return b1 or b2 end
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,2))+1
	end
	e:SetLabel(op)
end

function s.trop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetLabel()==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			local tc=g:GetFirst()
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local tc=Duel.SelectMatchingCard(tp,s.protfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
		if tc then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_IMMUNE_EFFECT)
			e1:SetValue(s.efilter)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	end
end

function s.efilter(e,re)
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
