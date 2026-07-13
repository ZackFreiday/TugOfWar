using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace TugOfWar.Application.DTOs;

public class SubmitVoteRequest
{
    [EnumDataType(typeof(ChosenSide))]
    public ChosenSide ChosenSide { get; set; }

    [Range(0, 50)]
    public int CoinBoostSupport { get; set; }
}
