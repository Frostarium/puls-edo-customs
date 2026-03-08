
--Cruel Stranger
local s,id=GetID()
function s.initial_effect(c)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
    e1:SetCode(EVENT_RELEASE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetRange(LOCATION_MZONE)
    e1:SetTarget(s.lvtg)
    e1:SetOperation(s.lvop)
    c:RegisterEffect(e1)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
    
end
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.HasLevel,1),tp,0,LOCATION_MZONE,1,nil)
end
-- s.op: Reduces opponent's monsters' levels by 4; if reduced below 1, send to GY
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.HasLevel,tp,0,LOCATION_MZONE,1,nil)
    for tc in aux.Next(g) do
        if tc:IsLevelAbove(1) then
            local lv=tc:GetLevel()
            local new_lv=lv-3
            if new_lv<1 then
                Duel.SendtoGrave(tc,REASON_EFFECT)
            else
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_UPDATE_LEVEL)
                e1:SetValue(-3)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
                tc:RegisterEffect(e1)
            end
        end
    end
end
function s.thfilter(c)
	return c:IsSetCard(0x67e)and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end