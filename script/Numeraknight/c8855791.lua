--Numeraknight Procefortress
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    
    --Special Summon effect
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_FZONE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    
    --Recovery effect
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetRange(LOCATION_FZONE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

function s.tgfilter(c,tp)
    if not (c:IsSetCard(0x657) and c:HasLevel()) then return false end
    local g=Duel.GetMatchingGroup(s.tgfilter2,tp,LOCATION_GRAVE,0,c,c:GetLevel())
    return #g>0
end

function s.tgfilter2(c,lv)
    return c:IsSetCard(0x657) and c:HasLevel() and c:GetLevel()~=lv
end

function s.spfilter(c,lv,e,tp)
    return c:IsSetCard(0x657) and c:IsLevel(lv) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.xyzfilter(c,mg)
    return c:IsSetCard(0x657) and c:IsXyzSummonable(nil,mg,2,2)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_GRAVE,0,1,nil,tp) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g1=Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_GRAVE,0,1,1,nil,tp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g2=Duel.SelectTarget(tp,s.tgfilter2,tp,LOCATION_GRAVE,0,1,1,g1:GetFirst(),g1:GetFirst():GetLevel())
    g1:Merge(g2)
    
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g1,2,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g~=2 then return end
    local lv1=g:GetFirst():GetLevel()
    local lv2=g:GetNext():GetLevel()
    local sumlv=lv1+lv2
    local diflv=math.abs(lv1-lv2)
    
    if sumlv>=10 and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_EXTRA,0,1,nil,0x657) 
        and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local xyz=Duel.SelectMatchingCard(tp,aux.AND(Card.IsSetCard,Card.IsCanBeSpecialSummoned),tp,LOCATION_EXTRA,0,1,1,nil,0x657,e,0,tp):GetFirst()
        if xyz then
            Duel.SpecialSummon(xyz,0,tp,tp,false,false,POS_FACEUP)
        end
    else
        if Duel.SendtoDeck(g,nil,2,REASON_EFFECT)~=2 then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,sumlv,e,tp)
        local sg2=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,diflv,e,tp)
        sg:Merge(sg2)
        if #sg>0 then
            local sc=sg:Select(tp,1,1,nil):GetFirst()
            Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    if not (re and re:IsActivated() and re:IsMonsterEffect()) then return false end
    if not eg:IsExists(Card.IsReason,1,nil,REASON_COST) then return false end
    local rc=re:GetHandler()
    return rc:IsSetCard(0x657)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return eg:IsExists(Card.IsAbleToHand,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=eg:Filter(Card.IsAbleToHand,nil)
    Duel.SetTargetCard(g)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
    end
end
