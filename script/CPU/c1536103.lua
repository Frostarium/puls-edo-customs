--CPU Attacker
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon self
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.hspcon)
	e1:SetTarget(s.hsptg)
	e1:SetOperation(s.hspop)
	c:RegisterEffect(e1)
    --direct attack
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_DIRECT_ATTACK)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsCode,1536101))
	c:RegisterEffect(e2)
    -- Quick Effect Copy while I control CPU
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.spellcon)
    e3:SetTarget(s.spelltg)
    e3:SetOperation(s.spellop)
    c:RegisterEffect(e3)
end
function s.hspcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,1536100),tp,LOCATION_ONFIELD,0,1,nil)
end
function s.hsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.hspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end
function s.spell_filter(c,tp)
	return c:IsSetCard(0x1456) and c:IsType(TYPE_SPELL) and c:IsNormalSpell() and c:IsControler(tp) and c:CheckActivateEffect(false,true,false)~=nil
end
function s.spelltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spell_filter,tp,LOCATION_GRAVE,0,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectMatchingCard(tp,s.spell_filter,tp,LOCATION_GRAVE,0,1,1,nil,tp)
	Duel.SetTargetCard(g)
end
function s.spellop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		local reset=RESET_SELF_TURN
		if Duel.IsTurnPlayer(tp) then reset=RESET_OPPO_TURN end
		c:RegisterFlagEffect(id,RESETS_STANDARD_PHASE_END|reset,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,2))
	end
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		-- Apply the effect of the selected spell card as if it were activated
		local te=tc:GetActivateEffect()
		if te then
			local tg=te:GetTarget()
			local op=te:GetOperation()
			if tg then tg(te,tp,eg,ep,ev,re,r,rp,1) end
			if op then op(te,tp,eg,ep,ev,re,r,rp) end
		end
	end
end
function s.spellcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,1536101),tp,LOCATION_ONFIELD,0,1,nil)
end