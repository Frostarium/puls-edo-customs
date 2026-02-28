--Arbiter of the Divine
local s,id=GetID()
function s.initial_effect(c)
--Special Summon by tributing DIVINE monster
local e1=Effect.CreateEffect(c)
e1:SetDescription(aux.Stringid(id,0))
e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
e1:SetType(EFFECT_TYPE_IGNITION)
e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
e1:SetCountLimit(1,{id,0})
e1:SetCost(s.spcost)
e1:SetTarget(s.sptg)
e1:SetOperation(s.spop)
c:RegisterEffect(e1)
--Remove card
local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id,0))
e2:SetCategory(CATEGORY_REMOVE)
e2:SetType(EFFECT_TYPE_QUICK_O)
e2:SetCode(EVENT_FREE_CHAIN)
e2:SetHintTiming(0,TIMING_END_PHASE)
e2:SetCountLimit(1,{id,1})
e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
e2:SetCondition(function(e) return not e:GetHandler():HasFlagEffect(id) end, function() return Duel.IsMainPhase() end)
e2:SetRange(LOCATION_MZONE)
e2:SetTarget(s.rmtg)
e2:SetOperation(s.rmop)
c:RegisterEffect(e2)
--Target Erase
local e3=Effect.CreateEffect(c)
e3:SetDescription(aux.Stringid(id,1))
e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e3:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
e3:SetCode(EVENT_TO_GRAVE)
e3:SetCountLimit(1,{id,2})
e3:SetTarget(s.divsptg)
e3:SetOperation(s.divspop)
c:RegisterEffect(e3)
end
function s.cfilter(c)
    return c:IsReleasable()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,e:GetHandler())
    Duel.Release(g,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        c:RegisterFlagEffect(id,RESETS_STANDARD_PHASE_END,EFFECT_FLAG_CLIENT_HINT,2,0,aux.Stringid(id,2))
    end
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) then
        local g=Group.FromCards(tc)
        local eg=tc:GetEquipGroup()
        if #eg>0 then
            g:Merge(eg)
        end
        g:ForEach(function(c) c:ResetEffect(RESETS_STANDARD,RESET_EVENT) end)
        if tc:IsType(TYPE_XYZ) and tc:GetOverlayCount()>0 then
            local og=tc:GetOverlayGroup()
            og:ForEach(function(c) c:ResetEffect(RESETS_STANDARD,RESET_EVENT) end)
            Duel.RemoveCards(og)
        end
        Duel.RemoveCards(g)
    end
end

function s.divinefilter (c,e,tp,ft)
    return c:IsAttribute(ATTRIBUTE_DIVINE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.divsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.divinefilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.divspop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.divinefilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end