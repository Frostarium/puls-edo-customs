--Futile Engine Y
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Copy from hand/GY when opponent activates hand effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetHintTiming(0,TIMING_MAIN_END|TIMINGS_CHECK_MONSTER)
	e2:SetCountLimit(1,id)
	e2:SetCondition(function(e,tp) return Duel.IsMainPhase() and Duel.GetCustomActivityCount(id,1-tp,ACTIVITY_CHAIN)>0 end)
	e2:SetTarget(s.copytg)
	e2:SetOperation(s.copyop)
	c:RegisterEffect(e2)
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,s.chainfilter)
	--Copy from Extra Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.spcon)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

function s.chainfilter(re,tp,cid)
    return not (re:GetActivateLocation()==LOCATION_HAND)
end

function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.copyop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g1=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    local g2=Duel.GetFieldGroup(tp,0,LOCATION_GRAVE)
    if #g1>0 then Duel.ConfirmCards(tp,g1) end
    if #g1<=0 and #g2<=0 then return end
    local sg=Group.CreateGroup()
    local b1=#g1>0
    local b2=#g2>0
    local op=Duel.SelectEffect(tp,
        {b1,aux.Stringid(id,2)},
        {b2,aux.Stringid(id,3)})
    if op==1 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        sg=g1:Select(tp,1,1,nil)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        sg=g2:Select(tp,1,1,nil)
    end
    if #sg>0 then
        local tc=sg:GetFirst()
        local token=Duel.CreateToken(tp,tc:GetCode())
        Duel.SendtoHand(token,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,token)
    end
    if #g1>0 then Duel.ShuffleHand(1-tp) end
end

function s.namefilter(c,code)
	return c:IsFaceup() and c:IsCode(code)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,nil)
	local checked={}
	for tc in aux.Next(g) do
		if not checked[tc:GetCode()] then
			checked[tc:GetCode()]=true
			local count=g:FilterCount(s.namefilter,nil,tc:GetCode())
			if count>=4 then return true end
		end
	end
	return false
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local g=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
    if #g>0 then
        Duel.ConfirmCards(tp,g)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local tc=g:Select(tp,1,1,nil):GetFirst()
        if tc then
            local token=Duel.CreateToken(tp,tc:GetCode())
            if Duel.SpecialSummon(token,0,tp,tp,true,true,POS_FACEUP)~=0 then
                if token:IsType(TYPE_XYZ) then
                    local mats=Group.CreateGroup()
                    for i=1,2 do
                        local mat=Duel.CreateToken(tp,token:GetCode())
                        if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT)~=0 then
                            mats:AddCard(mat)
                        end
                    end
                    if #mats>0 then
                        Duel.Overlay(token,mats)
                    end
                end
            end
        end
        Duel.ShuffleExtra(1-tp)
    end
end
