--Edge of Madness
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Halve LP and draw when Level 12 Fusion is summoned
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_RECOVER+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.lpcon)
	e2:SetTarget(s.lptg)
	e2:SetOperation(s.lpop)
	c:RegisterEffect(e2)
	--Prevent activation during Level 12 Fusion attacks
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetTargetRange(0,1)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.actcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	--Negate during Battle Phase
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_NEGATE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1,{id,2})
	e4:SetCondition(s.negcon)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end
function s.lpfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_FUSION) and c:IsLevel(12) and c:IsSummonType(SUMMON_TYPE_FUSION)
end
function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.lpfilter,1,nil)
end
function s.lptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	local lp=Duel.GetLP(1-tp)
	if Duel.SetLP(1-tp,math.ceil(lp/2))~=0 then
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end
function s.actcon(e)
    local ac=Duel.GetAttacker()
    return ac and ac:IsControler(e:GetHandlerPlayer()) and ac:IsType(TYPE_FUSION) and ac:IsLevel(12) and Duel.GetCurrentPhase()==PHASE_DAMAGE
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase() and rp==1-tp and Duel.IsChainNegatable(ev) and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end