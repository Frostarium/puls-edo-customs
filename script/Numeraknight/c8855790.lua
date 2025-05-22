--Numeraknight 0
local s,id=GetID()
function s.initial_effect(c)
    	--Cannot be Special Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e1)
	
	--Add from GY during Standby
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.thcon)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
    --Reveal to search
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_HAND)
    e3:SetCountLimit(1,id)
    e3:SetCost(s.rvcost)
    e3:SetTarget(s.rvtg)
    e3:SetOperation(s.rvop)
    c:RegisterEffect(e3)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    if not (e:GetHandler():IsReason(REASON_COST) and re:IsActivated() and re:IsMonsterEffect()) then return false end
    local rc=re:GetHandler()
    if rc:IsRelateToEffect(re) and rc:IsFaceup() then
        return rc:IsSetCard(0x657)
    else
        return (re:GetHandler():IsSetCard(0x657))
    end
end

function s.thfilter(c)
    return c:IsSetCard(0x657) and c:IsMonster() and c:IsAbleToHand()
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e1:SetCountLimit(1)
    e1:SetCondition(s.thcon2)
    e1:SetOperation(s.thop2)
    e1:SetLabel(e:GetLabel())
    e1:SetReset(RESET_PHASE+PHASE_STANDBY+RESET_EVENT+RESETS_STANDARD)
    Duel.RegisterEffect(e1,tp)
end

function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnCount()>e:GetLabel()
end

function s.thop2(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_CARD,0,id)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

function s.rvcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return not e:GetHandler():IsPublic() end
    Duel.ConfirmCards(1-tp,e:GetHandler())
end

function s.getlevels(tp)
    local levels={}
    local g=Duel.GetMatchingGroup(Card.HasLevel,tp,LOCATION_MZONE|LOCATION_GRAVE,0,nil)
    for tc in g:Iter() do
        levels[tc:GetLevel()]=true
    end
    return levels
end

function s.rvfilter(c,levels)
    if not (c:IsSetCard(0x657) and c:IsMonster() and c:IsAbleToHand() and c:HasLevel()) then return false end
    return not levels[c:GetLevel()]
end

function s.rvtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local levels=s.getlevels(tp)
    if chk==0 then return Duel.IsExistingMatchingCard(s.rvfilter,tp,LOCATION_DECK,0,1,nil,levels) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end

function s.rvop(e,tp,eg,ep,ev,re,r,rp)
    local levels=s.getlevels(tp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.rvfilter,tp,LOCATION_DECK,0,1,1,nil,levels)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
        Duel.ShuffleHand(tp)
        Duel.BreakEffect()
        Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
    end
end
