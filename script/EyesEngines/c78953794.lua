--Futile Engine Y
local s, id = GetID()
local function target_filter(c)
    return c:IsFaceup() or c:IsLocation(LOCATION_HAND) and c:IsMonster()
end

function s.initial_effect(c)
    --Activate
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    --Copy and summon on trigger
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_HAND)
    e2:SetCountLimit(2, { id, 0 })
    e2:SetRange(LOCATION_SZONE)
    e2:SetCondition(function(e, tp, eg, ep, ev, re, r, rp) return eg:IsExists(Card.IsControler, 1, nil, 1 - tp) and
        not Duel.IsPhase(PHASE_DRAW) end)
    e2:SetTarget(s.target)
    e2:SetOperation(s.operation)
    c:RegisterEffect(e2)
    local e3 = e2:Clone()
    e3:SetCode(EVENT_CHAIN_SOLVED)
    e3:SetCondition(s.condition2)
    c:RegisterEffect(e3)
    --Copy from Extra Deck
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetHintTiming(0, TIMING_END_PHASE)
    e4:SetCountLimit(1, { id, 1 })
    e4:SetRange(LOCATION_SZONE)
    e4:SetCondition(s.spcon)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

function s.condition2(e, tp, eg, ep, ev, re, r, rp)
    return rp ~= tp and re:IsMonsterEffect() and re:IsActivated() and re:GetActivateLocation() == LOCATION_HAND
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g1 = Duel.GetFieldGroup(tp, 0, LOCATION_HAND)
    local g2 = Duel.GetFieldGroup(tp, 0, LOCATION_MZONE)
    local g = g1:Clone()
    g:Merge(g2)
    if #g == 0 then return end
    Duel.ConfirmCards(tp, g1)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local tc = g:Filter(target_filter, nil):Select(tp, 1, 1, nil):GetFirst()
    if not tc then return end
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    local token = Duel.CreateToken(tp, tc:GetCode())
    if Duel.SpecialSummon(token, tc:GetSummonType(), tp, tp, true, true, POS_FACEUP) ~= 0 then
        token:CompleteProcedure()
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_BASE_ATTACK)
        e1:SetValue(3000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD)
        token:RegisterEffect(e1)
        local e2 = e1:Clone()
        e2:SetCode(EFFECT_SET_BASE_DEFENSE)
        token:RegisterEffect(e2)
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
    Duel.ShuffleHand(1 - tp)
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_MZONE + LOCATION_GRAVE, LOCATION_MZONE + LOCATION_GRAVE,
        nil)
    local checked = {}
    for tc in aux.Next(g) do
        if not checked[tc:GetCode()] then
            checked[tc:GetCode()] = true
            local count = g:FilterCount(s.namefilter, nil, tc:GetCode())
            if count >= 5 then return true end
        end
    end
    return false
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    local g = Duel.GetFieldGroup(tp, 0, LOCATION_EXTRA)
    if #g > 0 then
        Duel.ConfirmCards(tp, g)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local tc = g:Select(tp, 1, 1, nil):GetFirst()
        if tc then
            local token = Duel.CreateToken(tp, tc:GetCode())
            if Duel.SpecialSummon(token, tc:GetSummonType(), tp, tp, true, true, POS_FACEUP) ~= 0 then
                token:CompleteProcedure()
                if token:IsType(TYPE_XYZ) then
                    local mats = Group.CreateGroup()
                    for i = 1, 2 do
                        local mat = Duel.CreateToken(tp, token:GetCode())
                        if Duel.Remove(mat, POS_FACEUP, REASON_EFFECT) ~= 0 then
                            mats:AddCard(mat)
                        end
                    end
                    if #mats > 0 then
                        Duel.Overlay(token, mats)
                    end
                end
            end
        end
        Duel.ShuffleExtra(1 - tp)
    end
end

function s.namefilter(c, code)
    return c:IsFaceup() and c:IsCode(code)
end
