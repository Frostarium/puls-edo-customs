--GodMind Universe Hacking
--Continuous Spell. You can add 1 "GodMind" monster from your GY or banishment to your hand. You can only use this effect of "GodMind Universe Hacking" once per turn.
--While you control 3 or more "GodMind" Fusion, Synchro, Xyz, and/or Link Monsters, your opponent cannot activate cards or effects
--in response to the activation of effects of "GodMind" Fusion, Synchro, Xyz, and Link Monsters you control.
local s,id=GetID()
local SET_GODMIND=0x1650
local EXTRA_TYPES=TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--Add 1 "GodMind" monster from your GY or banishment to your hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--While you control 3+ "GodMind" Extra Deck monsters, your opponent cannot respond to their effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.limcon)
	e2:SetOperation(s.limop)
	c:RegisterEffect(e2)
end
function s.thfilter(c)
	return c:IsSetCard(SET_GODMIND) and c:IsMonster() and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
function s.edfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_GODMIND) and c:IsType(EXTRA_TYPES)
end
function s.limcon(e,tp,eg,ep,ev,re,r,rp)
	if ep~=tp or not re:IsMonsterEffect() then return false end
	local rc=re:GetHandler()
	return rc:IsSetCard(SET_GODMIND) and rc:IsType(EXTRA_TYPES)
		and Duel.GetMatchingGroupCount(s.edfilter,tp,LOCATION_MZONE,0,nil)>=3
end
function s.limop(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimit(s.chainlm)
end
function s.chainlm(e,rp,tp)
	return tp==rp
end
