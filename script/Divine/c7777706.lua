--Harbinger of the Divine
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon by tributing DIVINE monster
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
    e1:SetCountLimit(1,{id,0})
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    --Annihilate top 3 cards
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EVENT_CHAINING)
    e2:SetCountLimit(1,{id,1})
	e2:SetCondition(function(_,tp,_,ep) return ep==1-tp end)
    e2:SetTarget(s.anntg)
    e2:SetOperation(s.annop)
    c:RegisterEffect(e2)
    
    --Annihilate searched cards
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_TO_HAND)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.srchcon)
    e3:SetTarget(s.srchtg)
    e3:SetOperation(s.srchop)
    c:RegisterEffect(e3)
end

function s.cfilter(c)
    return c:IsAttribute(ATTRIBUTE_DIVINE) and c:IsReleasable()
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

--Annihilation functions

function s.anntg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>=3 end
end

function s.annop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)<3 then return end
    local g=Duel.GetDecktopGroup(1-tp,3)
    if #g>0 then
        Duel.RemoveCards(g)
    end
end

--Search annihilation functions
function s.srchcon(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetCurrentPhase()==PHASE_DRAW then return false end
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsAttribute,ATTRIBUTE_DIVINE),tp,LOCATION_MZONE,0,2,nil)
        and eg:IsExists(Card.IsControler,1,nil,1-tp)
        and r&REASON_EFFECT~=0 and rp==1-tp
end

function s.srchfilter(c,tp)
    return c:IsControler(1-tp) and c:IsPreviousLocation(LOCATION_DECK)
end

function s.srchtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return eg:IsExists(s.srchfilter,1,nil,tp) end
    local g=eg:Filter(s.srchfilter,nil,tp)
    Duel.SetTargetCard(g)
end

function s.srchop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g>0 then
        Duel.RemoveCards(g)
    end
end
