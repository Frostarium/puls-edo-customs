--Hecatoncheire Phylake
local s,id=GetID()
function s.initial_effect(c)
	--Activate as Field Spell
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- 1. At end of Damage Step, return opponent's monster to hand if your Hecatoncheire battled it
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_DAMAGE_STEP_END)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- 2. Ignition: Add 1 Hecatoncheire card from Deck to hand, then choose to discard 1 or opponent draws 1
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.srtg)
	e3:SetOperation(s.srop)
	c:RegisterEffect(e3)

	-- 3. If sent to GY by opponent's card effect, take control of 1 opponent's monster (no targeting)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_CONTROL)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCountLimit(1,{id,2})
	e4:SetCondition(s.ctcon)
	e4:SetTarget(s.cttg)
	e4:SetOperation(s.ctop)
	c:RegisterEffect(e4)
end

-- 1. Damage Step effect
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    local a=Duel.GetAttacker()
    local d=Duel.GetAttackTarget()
    if not d then return false end
    if a:IsControler(tp) then
        return a:IsSetCard(0x1cc) and d:IsControler(1-tp)
    else
        return d:IsSetCard(0x1cc) and a:IsControler(1-tp)
    end
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local a=Duel.GetAttacker()
    local d=Duel.GetAttackTarget()
    local tc=(a:IsControler(1-tp) and a) or d
    if chk==0 then return tc and tc:IsAbleToHand() and tc:IsControler(1-tp) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,tc,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local a=Duel.GetAttacker()
    local d=Duel.GetAttackTarget()
    local tc=(a:IsControler(1-tp) and a) or d
    if tc and tc:IsRelateToBattle() and tc:IsControler(1-tp) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
    end
end

-- 2. Ignition: Search + choose discard or opponent draws
function s.srfilter(c)
	return c:IsSetCard(0x1cc) and c:IsAbleToHand() and c:IsMonster(c)
end
function s.srtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.srfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.srop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.srfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		-- Choose: Discard 1 or opponent draws 1
		local opt=0
		if Duel.IsPlayerCanDiscardDeck(tp,1) and Duel.IsPlayerCanDraw(1-tp,1) then
			opt=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
		elseif Duel.IsPlayerCanDiscardDeck(tp,1) then
			opt=0
		else
			opt=1
		end
		if opt==0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
			local dg=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,1,1,nil)
			if #dg>0 then
				Duel.SendtoGrave(dg,REASON_DISCARD+REASON_EFFECT)
			end
		else
			Duel.Draw(1-tp,1,REASON_EFFECT)
		end
	end
end

-- 3. Sent to GY by opponent's card effect: Take control of 1 monster (no targeting)
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_EFFECT) and rp~=tp
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,nil) end
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
		local sg=g:Select(tp,1,1,nil)
		if #sg>0 then
			Duel.GetControl(sg:GetFirst(),tp)
		end
	end
end