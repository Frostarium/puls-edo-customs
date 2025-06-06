-- Bond Between Sensei and Pupil

local s,id=GetID()
function s.initial_effect(c)
    
--activate
local e1=Effect.CreateEffect(c)
e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
e1:SetType(EFFECT_TYPE_ACTIVATE)
e1:SetCode(EVENT_FREE_CHAIN)
e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
e1:SetCondition(s.condition)
e1:SetTarget(s.target)
e1:SetOperation(s.activate)
c:RegisterEffect(e1)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
return Duel.IsExistingMatchingCard(s.scfilter,tp,LOCATION_ONFIELD,0,1,nil)
end
function s.filter(c,e,tp)
return c:IsSetCard(SET_SWORDSOUL) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.setfilter(c)
return c:IsCode(14821890) and c:IsSSetable()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
if Duel.GetLocationCount(tp,LOCATION_MZONE)<1 then return end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
local sc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.filter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
if sc and Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)~=0 then
    local g=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)
    if #g>0 and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local tc=g:Select(tp,1,1,nil)
        Duel.SSet(tp,tc)
    end
end
end
function s.scfilter(c)
    return c:IsFaceup() and c:IsSetCard(SET_SWORDSOUL)
end