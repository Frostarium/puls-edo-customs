-- Swordsoul of Noxian

local s,id=GetID()
function s.initial_effect(c)
--send to grave
local e1=Effect.CreateEffect(c)
e1:SetDescription(aux.Stringid(id,0))
e1:SetCategory(CATEGORY_TOGRAVE)
e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCost(s.cost)
e1:SetTarget(s.tktg)
e1:SetOperation(s.operation)
c:RegisterEffect(e1)
local e2=e1:Clone()
e2:SetCode(EVENT_SPSUMMON_SUCCESS)
c:RegisterEffect(e2)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e3:SetCode(EVENT_BE_MATERIAL)
e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_PLAYER_TARGET)
e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.drcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end
s.listed_series={0x16d}
s.listed_names={id}
function s.tgfilter(c)
return (c:IsSetCard(0x16d) or c:IsRace(RACE_WYRM)) and not c:IsCode(id) and c:IsMonster() and c:IsAbleToHand()
end
function s.tsfilter(c)
return (c:IsSetCard(0x16d) or c:IsRace(RACE_WYRM)) and not c:IsCode(id) and c:IsMonster() and c:IsAbleToGrave()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.tgfilter(chkc) end
if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_GRAVE,0,1,nil) end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
local sg=Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_GRAVE,0,1,1,nil)
Duel.SetOperationInfo(0,CATEGORY_TOHAND,sg,#sg,0,0)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tsfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tsfilter,tp,LOCATION_DECK,0,1,1,nil)
    Duel.SendtoGrave(g,REASON_COST)
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then
return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_SWORDSOUL,0x16d,TYPES_TOKEN+TYPE_TUNER,0,0,4,RACE_WYRM,ATTRIBUTE_WATER)
end
Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
if s.tktg(e,tp,eg,ep,ev,re,r,rp,0) then
local c=e:GetHandler()
local token=Duel.CreateToken(tp,TOKEN_SWORDSOUL)
Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP)
-- Cannot Special Summon non-Synchro monsters from Extra Deck
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_FIELD)
e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
e1:SetRange(LOCATION_MZONE)
e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
e1:SetAbsoluteRange(tp,1,0)
e1:SetTarget(function(_,c) return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_SYNCHRO) end)
e1:SetReset(RESET_EVENT+RESETS_STANDARD)
token:RegisterEffect(e1,true)
-- Lizard check
local e2=aux.createContinuousLizardCheck(c,LOCATION_MZONE,function(_,c) return not c:IsOriginalType(TYPE_SYNCHRO) end)
e2:SetReset(RESET_EVENT+RESETS_STANDARD)
token:RegisterEffect(e2,true)
end
Duel.SpecialSummonComplete()
end
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
return e:GetHandler():IsLocation(LOCATION_GRAVE) and r==REASON_SYNCHRO
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
local tc=Duel.GetFirstTarget()
if tc and tc:IsRelateToEffect(e) then
Duel.SendtoHand(tc,nil,REASON_EFFECT)
end
end