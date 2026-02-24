--One for the Team
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	--Check for flag
	aux.GlobalCheck(s,function()
		s.flagmap={}
	end)
end
s.listed_names={7458100} --Reality Core

function s.tgfilter(c)
	return c:IsMonster() and c:ListsCode(7458100) and c:IsAbleToGrave()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) 
		and Duel.GetFlagEffect(tp,id)==0 end --Check if this effect has been used this turn
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--Check flag again in case something changed between activation and resolution
	if Duel.GetFlagEffect(tp,id)>0 then return end
	
	--Register flag effect - once per turn
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	
	if tc and Duel.SendtoGrave(tc,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_GRAVE) then
		local lv=tc:GetLevel()
		
		--Opponent cannot activate cards/effects when a monster that mentions Reality Core is summoned
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_SUMMON_SUCCESS)
		e1:SetOperation(s.sumop)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		local e2=e1:Clone()
		e2:SetCode(EVENT_SPSUMMON_SUCCESS)
		Duel.RegisterEffect(e2,tp)
		
		--Option to reduce ATK/DEF
		local reduce_atk = false
		if Duel.IsExistingMatchingCard(Card.IsFaceup,1-tp,LOCATION_MZONE,0,1,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			reduce_atk = true
		end
		
		if reduce_atk then
			--Reduce opponent monsters' ATK/DEF
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetType(EFFECT_TYPE_FIELD)
			e3:SetCode(EFFECT_UPDATE_ATTACK)
			e3:SetTargetRange(0,LOCATION_MZONE)
			e3:SetValue(-lv*200)
			e3:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e3,tp)
			local e4=e3:Clone()
			e4:SetCode(EFFECT_UPDATE_DEFENSE)
			Duel.RegisterEffect(e4,tp)
		end
		
		--Client hint
		aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,0),nil)
	end
end

function s.corefilter(c,tp)
	return c:IsFaceup() and c:IsMonster() and c:ListsCode(7458100) and c:IsControler(tp)
end

function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(s.corefilter,1,nil,tp) then
		Duel.SetChainLimitTillChainEnd(function(e,rp,tp) return tp==rp end)
	end
end
