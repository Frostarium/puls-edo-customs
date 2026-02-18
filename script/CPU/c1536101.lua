--CPU 
local s,id=GetID()
function s.initial_effect(c)
	-- 1. Special Summon self if field spell exists
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCondition(s.sprcon)
	c:RegisterEffect(e1)
    --Special summon a CPU
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetCondition(function() return Duel.IsPhase(PHASE_MAIN1) end)
	e2:SetCountLimit(1,{id,1})
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	-- 3. Trigger: When opponent targets a CPU monster, apply CPU normal spell effect from GY (targets the spell)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.spellcon)
	e3:SetTarget(s.spelltg)
	e3:SetOperation(s.spellop)
	c:RegisterEffect(e3)
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(Card.IsFaceup,0,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end
function s.cpufilter(c,e,tp)
	return c:IsSetCard(0x1456) and c:IsLevelBelow(5) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.cpufilter,tp,LOCATION_GRAVE+LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.cpufilter),tp,LOCATION_GRAVE+LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
function s.spellcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
end
function s.spell_filter(c,tp)
	return c:IsSetCard(0x1456) and c:IsType(TYPE_SPELL) and c:IsType(TYPE_NORMAL) and c:IsAbleToHand() and c:IsControler(tp)
end
function s.spelltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spell_filter,tp,LOCATION_GRAVE,0,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectMatchingCard(tp,s.spell_filter,tp,LOCATION_GRAVE,0,1,1,nil,tp)
	Duel.SetTargetCard(g)
end
function s.spellop(e,tp,eg,ep,ev,re,r,rp)
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