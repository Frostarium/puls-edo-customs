--GodMind Technarch
--Xyz: 2 Level 4 monsters
--Once per turn (Ignition): detach 1 material from this card, then target 1 face-up monster on the field; apply the effects of
--"Forbidden Crown" to it until the end of this turn (negated, cannot attack, cannot be destroyed by battle or card effects, unaffected
--by activated effects except its own and this card's, cannot be Tributed, cannot be used as material for a Fusion / Synchro / Xyz /
--Link Summon).
--During the End Phase (once per turn): you can attach the monster you affected this turn to this card as material.
--(While "GodMind Processing Universe" is face-up on your field it adds a Quick Effect clone of the Ignition Effect.)
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,4,2)
	--Ignition: detach 1, apply "Forbidden Crown" to 1 face-up monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.detachcost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--End Phase: attach the monster affected this turn
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.atcon)
	e2:SetTarget(s.attg)
	e2:SetOperation(s.atop)
	c:RegisterEffect(e2)
end
--the monster affected by THIS card this turn is marked with a flag whose label is this card's field ID
function s.afilter(c,tp)
	return c:IsFaceup() and not c:HasFlagEffect(id)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.afilter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.afilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	local g=Duel.SelectTarget(tp,s.afilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sc=Duel.GetFirstTarget()
	if not (sc and sc:IsRelateToEffect(e) and sc:IsFaceup()) then return end
	s.apply(c,sc)
end
--apply the "Forbidden Crown" effects of card c to monster sc until the end of this turn
--(split out so that "GodMind Processor 10² Technarch" can apply them to up to 2 monsters with the same code)
--detach 1 material from this card (written out by hand: "Cost.Detach" and "Cost.DetachFromSelf" exist in different versions of utility.lua)
function s.detachcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.apply(c,sc)
	--marker: this monster was affected by this card this turn (also stops it from being picked again)
	sc:RegisterFlagEffect(id,RESETS_STANDARD_PHASE_END,EFFECT_FLAG_CLIENT_HINT,1,c:GetFieldID(),aux.Stringid(id,2))
	--Its effects are negated
	sc:NegateEffects(c,RESETS_STANDARD_PHASE_END)
	--It cannot attack
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EFFECT_CANNOT_ATTACK)
	e1:SetReset(RESETS_STANDARD_PHASE_END)
	sc:RegisterEffect(e1)
	--It cannot be destroyed by battle or card effects
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetValue(1)
	sc:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	sc:RegisterEffect(e3)
	--It is unaffected by other cards' activated effects, except its own (and this card's, so that it can attach it)
	local e4=e1:Clone()
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetValue(function(e,re)
		return re:IsActivated() and e:GetHandler()~=re:GetOwner() and re:GetOwner()~=c
	end)
	sc:RegisterEffect(e4)
	--It cannot be Tributed
	local e5=e2:Clone()
	e5:SetCode(EFFECT_UNRELEASABLE_SUM)
	sc:RegisterEffect(e5)
	local e6=e2:Clone()
	e6:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	sc:RegisterEffect(e6)
	--It cannot be used as material for a Fusion, Synchro, Xyz or Link Summon
	local e7=e1:Clone()
	e7:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e7:SetValue(aux.cannotmatfilter(SUMMON_TYPE_FUSION,SUMMON_TYPE_SYNCHRO,SUMMON_TYPE_XYZ,SUMMON_TYPE_LINK))
	sc:RegisterEffect(e7)
end
--End Phase: attach the affected monster to this card
function s.atfilter(c,fid)
	return c:IsFaceup() and c:GetFlagEffectLabel(id)==fid
end
function s.atcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsType(TYPE_XYZ) and Duel.IsExistingMatchingCard(s.atfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,c:GetFieldID())
end
function s.attg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.atop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and c:IsType(TYPE_XYZ)) then return end
	local g=Duel.GetMatchingGroup(s.atfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil,c:GetFieldID())
	if #g>0 then
		Duel.Overlay(c,g)
	end
end
