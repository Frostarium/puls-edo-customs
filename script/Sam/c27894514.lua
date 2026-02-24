--D.J. NG-L
local s,id=GetID()
function s.initial_effect(c)
		--Special Summon this card by targeting a face-up card you control, then flip it facedown
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,1))
		e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e1:SetType(EFFECT_TYPE_IGNITION)
		e1:SetRange(LOCATION_HAND|LOCATION_GRAVE)
		e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
		e1:SetTarget(s.sptg)
		e1:SetOperation(s.spop)
		c:RegisterEffect(e1)
	end

	function s.filter(c)
		return c:IsFaceup() and (
			(c:IsType(TYPE_MONSTER) and c:IsCanTurnSet()) or
			((c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsSSetable(true))
		)
	end

	function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
		if chkc then return chkc:IsOnField() and s.filter(chkc) end
		if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_ONFIELD,0,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	end

	function s.spop(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		local tc=Duel.GetFirstTarget()
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
				if tc:IsType(TYPE_MONSTER) then
					Duel.ChangePosition(tc,POS_FACEDOWN_DEFENSE)
				elseif tc:IsType(TYPE_SPELL) or tc:IsType(TYPE_TRAP) then
					Duel.ChangePosition(tc,POS_FACEDOWN)
				end
			end
		end
	end
