--Eye of Universes
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Copy monster on summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(2)
	e2:SetRange(LOCATION_FZONE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	--Set this card
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY,EFFECT_FLAG2_CHECK_SIMULTANEOUS)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.setcon)
	e4:SetTarget(s.settg)
	e4:SetOperation(s.setop)
	c:RegisterEffect(e4)
end

function s.filter(c,tp)
	return c:IsFaceup() and c:IsControler(1-tp)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and eg:IsExists(s.filter,1,nil,tp) end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local g=eg:Filter(s.filter,nil,tp)
	if #g>0 then
		local tc=g:GetFirst()
		if #g>1 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
			tc=g:Select(tp,1,1,nil):GetFirst()
		end
		local token=Duel.CreateToken(tp,tc:GetCode())
		if Duel.SpecialSummon(token,tc:GetSummonType(),tp,tp,true,true,POS_FACEUP)~=0 then
			token:CompleteProcedure()
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_BASE_ATTACK)
			e1:SetValue(tc:GetBaseAttack()*3/4)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_SET_BASE_DEFENSE)
			e2:SetValue(tc:GetBaseDefense()*3/4)
			token:RegisterEffect(e2)
			--Copy Xyz materials if applicable
			if token:IsType(TYPE_XYZ) and tc:IsType(TYPE_XYZ) and tc:GetOverlayCount()>0 then
				local og=tc:GetOverlayGroup()
				local mg=Group.CreateGroup()
				for oc in aux.Next(og) do
					local mat=Duel.CreateToken(tp,oc:GetCode())
					if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT)~=0 then
						mg:AddCard(mat)
					end
				end
				if #mg>0 then
					Duel.Overlay(token,mg)
				end
			end
		end
	end
end
function s.setconfilter(c,tp)
	return c:IsReason(REASON_BATTLE|REASON_EFFECT)
		and c:GetPreviousControler()==tp and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and not eg:IsContains(e:GetHandler()) and eg:IsExists(s.setconfilter,1,nil,tp)
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,tp,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.MoveToField(c,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
	end
end