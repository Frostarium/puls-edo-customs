--Star Signis Sparkle
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCondition(s.grave_condition)
    e2:SetTarget(s.grave_target)
    e2:SetOperation(s.grave_operation)
    e2:SetCountLimit(1,id)
    c:RegisterEffect(e2)
end
function s.tgfilter(c)
	return c:IsSetCard(0xbbb) and c:IsAbleToGrave() and c:IsMonster()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.filter(c)
    return c:IsSetCard(0xbbb) and c:IsMonster()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT) > 0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
        if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0) < Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE) then
            local sg=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
            sg:Remove(Card.IsCode,nil,g:GetFirst():GetCode())
            if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
                local tg=sg:Select(tp,1,1,nil)
                Duel.SendtoHand(tg,nil,REASON_EFFECT)
                Duel.ConfirmCards(1-tp,tg)
            end
        end
    end
end
function s.grave_condition(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(Card.IsLocation,1,nil,LOCATION_GRAVE) and eg:IsExists(Card.IsPreviousLocation,1,nil,LOCATION_HAND)
end
function s.grave_target(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToHand() end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
end
function s.grave_operation(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c,nil,REASON_EFFECT)
    end
end
