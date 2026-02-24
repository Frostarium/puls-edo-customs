--Invasion of the Realiteaters
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_names={7458100,7458112} --Reality Core and Arch-Realiteater

function s.cfilter(c,tp)
	return (c:IsFaceup() and c:IsCode(7458100)) or (c:IsFaceup() and c:IsCode(7458112) and c:IsControler(tp))
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,tp)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN,2500,2000,6,RACE_INSECT,ATTRIBUTE_DARK)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN,1500,1500,4,RACE_FIEND,ATTRIBUTE_DARK) then
		local token1=Duel.CreateToken(tp,id+1)
		local token2=Duel.CreateToken(tp,id+1)
		Duel.SpecialSummonStep(token1,0,tp,tp,false,false,POS_FACEUP)
		Duel.SpecialSummonStep(token2,0,tp,tp,false,false,POS_FACEUP)
		
		--Cannot be destroyed by spell/trap effects
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetValue(s.efilter)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		token1:RegisterEffect(e1)
		local e2=e1:Clone()
		token2:RegisterEffect(e2)
		
		Duel.SpecialSummonComplete()
		
		--Cannot Special Summon monsters for the rest of the turn except monsters that mention Reality Core
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetType(EFFECT_TYPE_FIELD)
		e3:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e3:SetDescription(aux.Stringid(id,0))
		e3:SetTargetRange(1,0)
		e3:SetTarget(s.splimit)
		e3:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e3,tp)
	end
end

function s.efilter(e,re)
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:ListsCode(7458100)
end
