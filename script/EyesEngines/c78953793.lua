--Paradox Engine V
local s, id = GetID()
function s.initial_effect(c)
	--Copy monster with doubled stats
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, { id, 1 })
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Copy from GY
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, { id, 1 })
	e2:SetCondition(s.spcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, 0)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	local tc = Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local token = Duel.CreateToken(tp, tc:GetCode())
		if Duel.SpecialSummon(token, 0, tp, tp, true, true, POS_FACEUP) ~= 0 then
			token:CompleteProcedure()
			--Destroy during End Phase
			local e4 = Effect.CreateEffect(e:GetHandler())
			e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
			e4:SetRange(LOCATION_MZONE)
			e4:SetCode(EVENT_PHASE + PHASE_END)
			e4:SetOperation(function(e) Duel.Destroy(e:GetHandler(), REASON_EFFECT) end)
			e4:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
			e4:SetCountLimit(1)
			token:RegisterEffect(e4)
			--Copy Xyz materials if applicable
			if token:IsType(TYPE_XYZ) and tc:IsType(TYPE_XYZ) and tc:GetOverlayCount() > 0 then
				local og = tc:GetOverlayGroup()
				local mg = Group.CreateGroup()
				for oc in aux.Next(og) do
					local mat = Duel.CreateToken(tp, oc:GetCode())
					if Duel.Remove(mat, POS_FACEUP, REASON_EFFECT) ~= 0 then
						mg:AddCard(mat)
					end
				end
				if #mg > 0 then
					Duel.Overlay(token, mg)
				end
			end
		end
	end
end

function s.namefilter(c, code)
	return c:IsFaceup() and c:IsCode(code)
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
	local checked = {}
	for tc in aux.Next(g) do
		if not checked[tc:GetCode()] then
			checked[tc:GetCode()] = true
			local count = g:FilterCount(s.namefilter, nil, tc:GetCode())
			if count >= 3 then return true end
		end
	end
	return false
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, nil)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	local tc = Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local token = Duel.CreateToken(tp, tc:GetCode())
		if Duel.SpecialSummon(token, 0, tp, tp, true, true, POS_FACEUP) ~= 0 then
			--Copy Xyz materials if applicable
			if token:IsType(TYPE_XYZ) and tc:IsType(TYPE_XYZ) and tc:GetOverlayCount() > 0 then
				local og = tc:GetOverlayGroup()
				local mg = Group.CreateGroup()
				for oc in aux.Next(og) do
					local mat = Duel.CreateToken(tp, oc:GetCode())
					if Duel.Remove(mat, POS_FACEUP, REASON_EFFECT) ~= 0 then
						mg:AddCard(mat)
					end
				end
				if #mg > 0 then
					Duel.Overlay(token, mg)
				end
			end
		end
	end
end
