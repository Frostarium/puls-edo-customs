--Superfluous Replicant Engine B
local s, id = GetID()
function s.initial_effect(c)
    --Activate
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    --Copy monster on summon
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetRange(LOCATION_SZONE)
    e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e2:SetCountLimit(1)
    e2:SetTarget(s.target)
    e2:SetOperation(s.operation)
    c:RegisterEffect(e2)
    local e3 = Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_TOGRAVE)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_SZONE)
    e3:SetHintTiming(0, TIMING_END_PHASE)
    e3:SetCountLimit(1, { id, 1 })
    e3:SetCondition(s.sendcon)
    e3:SetTarget(s.sendtg)
    e3:SetOperation(s.sendop)
    c:RegisterEffect(e3)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and
            Duel.IsExistingMatchingCard(s.monster_filter, 1 - tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, 1 - tp, LOCATION_GRAVE, LOCATION_REMOVED)
end

function s.monster_filter(c)
    return c:IsMonster() and not c:IsSpellTrap()
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, (s.monster_filter), 1 - tp, LOCATION_GRAVE|LOCATION_REMOVED, 0, 1, 1, nil)
    if #g > 0 then
        local tc = g:GetFirst()
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
    end
end

function s.sendcon(e, tp, eg, ep, ev, re, r, rp)
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

function s.sendtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsAbleToGrave() end
    if chk == 0 then return Duel.IsExistingTarget(Card.IsAbleToGrave, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
    local g = Duel.SelectTarget(tp, Card.IsAbleToGrave, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, g, 1, 0, 0)
end

function s.sendop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) then
        Duel.SendtoGrave(tc, REASON_EFFECT)
    end
end

function s.namefilter(c, code)
    return c:IsFaceup() and c:GetCode() == code
end
